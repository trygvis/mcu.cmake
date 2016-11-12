# Execute with cmake -P versions-tests.cmake

macro(do_test L R)
  set(eq FALSE)
  set(lt FALSE)
  set(gt FALSE)
  if(${L} VERSION_EQUAL ${R})
    set(eq TRUE)
  endif()
  if(${L} VERSION_LESS ${R})
    set(lt TRUE)
  endif()
  if(${L} VERSION_GREATER ${R})
    set(gt TRUE)
  endif()

  message("testing L=${L} R=${R}")
  message("    L = R => " ${eq})
  message("    L < R => " ${lt})
  message("    L > R => " ${gt})
endmacro()

do_test("1" "1")
do_test("1.0" "1.1")
do_test("1" "2")
do_test("1.0" "2.0")

do_test("1" "1.0")
