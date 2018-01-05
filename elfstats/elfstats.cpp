#include <cstdlib>
#include <inttypes.h>
#include <cstdio>
#include <cstring>
#include <map>

#include <err.h>
#include <sysexits.h>
#include <fcntl.h>
#include <vector>
#include <algorithm>
#include <getopt.h>
#include <elf.h>
#include <gelf.h>

using std::vector;
using std::map;

enum class SectionType {
    TEXT, DATA, BSS
};

const char *to_str(const SectionType &type) {
    switch (type) {
        case SectionType::TEXT:
            return "text";
        case SectionType::DATA:
            return "data";
        case SectionType::BSS:
            return "bss";
    }
}

struct section {
    const SectionType type;
    const Elf64_Addr start;
    const Elf64_Addr end;
    const Elf64_Xword size;
    Elf64_Addr used;

    section(SectionType type, Elf64_Addr start, Elf64_Xword size) :
            type(type), start(start), size(size), end(start + size), used(0) {}

    bool contains(Elf64_Addr address, Elf64_Xword size) const {
        return contains(address) && contains(address + size);
    }

    bool contains(Elf64_Addr address) const {
        return start <= address && address < end;
    }
};

enum class memory_type {
    RO, RW
};

const char *to_str(const memory_type &type) {
    switch (type) {
        case memory_type::RO:
            return "ro";
        case memory_type::RW:
            return "rw";
    }
}

struct memory_area {
    memory_type type;
    const Elf64_Addr start;
    const Elf64_Addr end;
    const Elf64_Xword size;
    Elf64_Addr high_mark;

    memory_area(memory_type type, Elf64_Addr start, Elf64_Xword size) :
            type(type), start(start), size(size), end(start + size), high_mark(start) {}

    bool contains(Elf64_Addr address) const {
        return start <= address && address < end;
    }

    void add_section(const section &section) {
        high_mark = std::max(high_mark, section.end);
    }

    Elf64_Addr used_bytes() {
        return high_mark - start;
    }
};

vector<memory_area> memory_areas;
vector<section> sections;

char *filename = NULL;

char *program;

__attribute__((noreturn))
void usage(const char *reason = NULL) {
    if (reason != NULL) {
        fprintf(stderr, "%s\n", reason);
    }
    fprintf(stderr, "usage: %s -f file [[-t | -d | -b] [start:size]]\n", program);
    fprintf(stderr, "  -t/-d/-b: add text/data/bss section\n");
    exit(EX_USAGE);
}

void parse_start_size(char *input, Elf64_Addr &start, Elf64_Xword &size) {
    char *str_size = strchr(input, ':');

    if (str_size == NULL) {
        usage("bad section specification, missing ':'");
    }

    *str_size = '\0';
    str_size++;

    if (sscanf(input, "%" SCNi64, &start) != 1) {
        usage("bad section specification, could not parse start number");
    }

    size_t str_size_len = strlen(str_size);

    if (str_size_len < 1) {
        usage("bad section specification");
    }

    char suffix = str_size[str_size_len - 1];
    int modifier;

    if (!isdigit(suffix)) {
        switch (suffix) {
            case 'k':
            case 'K':
                modifier = 1024;
                break;
            case 'm':
            case 'M':
                modifier = 1024 * 1024;
                break;
            default:
                usage("bad size modifier, only 'k' and 'M' are allowed");
        }
    } else {
        modifier = 1;
    }

    if (sscanf(str_size, "%" SCNi64, &size) != 1) {
        usage("bad section specification, could not parse size number");
    }
    size = size * modifier;
}

bool debug = false;

void parse_args(int argc, char **argv) {
    int c;

    while ((c = getopt(argc, argv, "Df:t:d:")) != -1) {
        switch (c) {
            case 'D':
                debug = true;
                break;
            case 't':
            case 'd': {
                Elf64_Addr start;
                Elf64_Xword size;
                parse_start_size(optarg, start, size);
                memory_type type = c == 't' ? memory_type::RO : memory_type::RW;
                memory_areas.emplace_back(type, start, size);
                break;
            }
            case 'f':
                filename = optarg;
                break;
            case '?':
                if (optopt == 'c')
                    errx(EX_USAGE, "Option -%c requires an argument.\n", optopt);
                else
                    errx(EX_USAGE, "Unknown option `-%c'.\n", optopt);
            default:
                abort();
        }
    }

    if (filename == NULL) {
        usage("Missing file name");
    }
}

std::string to_iso(Elf64_Addr i) {
    const auto M = 1024 * 1024;
    const auto k = 1024;
    if (i > M) {
        return std::to_string(i / M) + 'M';
    } else if (i > k) {
        return std::to_string(i / k) + 'k';
    } else {
        return std::to_string(i);
    }
}

int main(int argc, char **argv) {
    program = argv[0];
    parse_args(argc, argv);

    auto create_sections = sections.empty();

    if (elf_version(EV_CURRENT) == EV_NONE)
        errx(EX_SOFTWARE, "ELF library initialization failed: %s", elf_errmsg(-1));

    int fd;
    if ((fd = open(filename, O_RDONLY, 0)) < 0)
        err(EX_NOINPUT, "open \"%s\" failed", filename);

    Elf *e;
    if ((e = elf_begin(fd, ELF_C_READ, NULL)) == NULL)
        errx(EX_SOFTWARE, "elf_begin() failed: %s.", elf_errmsg(-1));
    if (elf_kind(e) != ELF_K_ELF)
        errx(EX_DATAERR, "%s is not an ELF object.", filename);

    size_t shstrndx;
    if (elf_getshdrstrndx(e, &shstrndx) != 0)
        errx(EX_SOFTWARE, "elf_getshdrstrndx() failed: %s.", elf_errmsg(-1));

    size_t program_header_count;
    if (elf_getphdrnum(e, &program_header_count) != 0)
        errx(EX_DATAERR, "elf_getphdrnum() failed: %s.", elf_errmsg(-1));

    for (int i = 0; i < program_header_count; i++) {
        GElf_Phdr phdr;

        if (gelf_getphdr(e, i, &phdr) != &phdr)
            errx(EX_SOFTWARE, "getphdr() failed: %s.", elf_errmsg(-1));

        if (phdr.p_type == PT_LOAD) {
            SectionType expectedType;

            bool r = phdr.p_flags & PF_R;
            bool w = phdr.p_flags & PF_W;
            bool x = phdr.p_flags & PF_X;

            if (x) {
                if (debug) {
                    printf("Adding PH #%d as text\n", i);
                }

                expectedType = SectionType::TEXT;
            } else if (r) {
                if (phdr.p_filesz > 0) {
                    expectedType = SectionType::DATA;
                    if (debug) {
                        printf("Adding PH #%d as data\n", i);
                    }
                } else {
                    expectedType = SectionType::BSS;
                    if (debug) {
                        printf("Adding PH #%d as bss\n", i);
                    }
                }
            } else {
                errx(EX_DATAERR, "Unknown flag combination: 0x%02x", phdr.p_flags);
            }

            auto s = std::find_if(sections.begin(), sections.end(), [&](section &section) {
                return section.type == expectedType && section.contains(phdr.p_vaddr, phdr.p_memsz);
            });

            struct section *found = nullptr;
            if (s == sections.end()) {
                sections.emplace_back(expectedType, phdr.p_vaddr, phdr.p_memsz);
                found = &sections[sections.size() - 1];
            } else {
                found = &(*s);
            }

            found->used += phdr.p_memsz;
        } else {
            // ignored
        };
    }

    size_t text = 0, data = 0, bss = 0;
    std::for_each(sections.begin(), sections.end(), [&](section &s) {
        if (s.type == SectionType::TEXT)
            text += s.size;
        else if (s.type == SectionType::DATA)
            data += s.size;
        else if (s.type == SectionType::BSS)
            bss += s.size;
    });

    if (!memory_areas.empty()) {
        for (auto &&section : sections) {
            for (auto &&area: memory_areas) {
                if (area.contains(section.start)) {
                    // TODO: could check if section.end is contained in the memory segment, but the user will see it
                    // anyway as usage will be > 100%

                    area.add_section(section);
                    break;
                }
            }
        }

        printf("Size by memory areas\n");
        printf("Type    Start      End  Size   Used\n");
        for (auto &&s: memory_areas) {
            std::string size = to_iso(s.size);
            auto used_pct = int(s.used_bytes() / double(s.size) * 100.0);

            printf("%-4s %08" PRIx64 " %08" PRIx64 " %5s %6" PRId64 " %3d%%\n",
                   to_str(s.type), s.start, s.end, size.c_str(), s.used_bytes(), used_pct);
        };
    }

    printf("\n");
    printf("Size by type\n");
    printf("  text % 7zu\n  data % 7zu\n  bss  % 7zu\n", text, data, bss);
    return EXIT_SUCCESS;
}
