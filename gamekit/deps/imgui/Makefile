# You will need SDL2 (http://www.libsdl.org):
# Linux:
#   apt-get install libsdl2-dev
# Mac OS X:
#   brew install sdl2
# MSYS2:
#   pacman -S mingw-w64-i686-SDL2

TARGET :=

CP := cp
CIMGUI := cimgui
IMGUI := $(CIMGUI)/imgui
$(shell mkdir -p build)

CFLAGS := -I.
CFLAGS += -DCIMGUI_DEFINE_ENUMS_AND_STRUCTS=1
CFLAGS += -DIMGUI_DISABLE_OBSOLETE_FUNCTIONS=1
CFLAGS += -DIMGUI_IMPL_OPENGL_LOADER_GL3W
CFLAGS += -DIMGUI_IMPL_API=extern\ \"C\"
CFLAGS += `sdl2-config --cflags`

## Using OpenGL loader: gl3w [default]
GL3W := $(CIMGUI)/imgui/examples/libs/gl3w
CFLAGS += -I$(GL3W)

TARGET += gl3w.o
TARGET += imgui_impl_sdl.o
TARGET += imgui_impl_opengl3.o

##---------------------------------------------------------------------
## BUILD FLAGS PER PLATFORM
##---------------------------------------------------------------------

UNAME_S := $(shell uname -s)
LIB_FOLDER :=

ifeq ($(UNAME_S), Linux) #LINUX
	CFLAGS += `sdl2-config --cflags`

	SED := sed -i
	TARGET += cimgui.so # not yet supported
else ifeq ($(UNAME_S), Darwin) #APPLE
	CFLAGS += `sdl2-config --cflags`
	CFLAGS += -I/usr/local/include
	CFLAGS += -Icimgui/imgui/examples/libs/gl3w

	SED := sed -i ''
endif

##---------------------------------------------------------------------
## BUILD RULES
##---------------------------------------------------------------------

all: $(TARGET)
	@echo build complete

gl3w.o: $(IMGUI)/examples/libs/gl3w/GL/gl3w.c
	$(CC) -fPIC -c -o build/$@ $^ -I$(GL3W) -fno-threadsafe-statics

imgui_impl_sdl.o: $(IMGUI)/examples/imgui_impl_sdl.cpp
	$(CXX) -fPIC -c -o build/$@ $^ -I$(IMGUI) `sdl2-config --cflags` -DIMGUI_IMPL_API=extern\ \"C\" -fno-threadsafe-statics

imgui_impl_opengl3.o: $(IMGUI)/examples/imgui_impl_opengl3.cpp
	$(CXX) -fPIC -c -o build/$@ $^ -I$(IMGUI) -I$(GL3W) $(CFLAGS) -DIMGUI_IMPL_API=extern\ \"C\" -fno-threadsafe-statics

clean:
	$(RM) *.o *.so *.h $(TARGET)

clobber: clean
	$(RM) -Rf build
