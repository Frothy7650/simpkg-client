module fs

#flag linux -ldl

fn C.dlopen(path &char, flag int) voidptr
fn C.dlclose(handle voidptr) int

#flag windows -lkernel32

fn C.LoadLibraryA(path &char) voidptr
fn C.FreeLibrary(hModule voidptr) bool
