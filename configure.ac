# Process this file with autoconf to produce a configure script.
AC_INIT([Common/TArray.cpp])
AM_INIT_AUTOMAKE(fivel, 0.0)

# Turn on debugging.
CFLAGS="$CFLAGS -g"
CXXFLAGS="$CXXFLAGS -g"

# Set up some compiler options for Unix.
AC_DEFINE(TEST_TYPOGRAPHY)
AC_DEFINE(HAVE_EYE_OF_GNOME)

# Figure out how to link against FreeType 2.
CFLAGS="$CFLAGS `freetype-config --cflags`"
CXXFLAGS="$CXXFLAGS `freetype-config --cflags`"
FREETYPE_LDADD="`freetype-config --libs`"
AC_SUBST(FREETYPE_LDADD)


#==========================================================================
# Checks for Programs
#==========================================================================

AC_PROG_RANLIB
AC_PROG_CXX
AC_PROG_CC

#==========================================================================
# Checks for Libraries
#==========================================================================


#==========================================================================
# Checks for Header Files
#==========================================================================

#==========================================================================
# Checks for Typedefs, Structures, and Compiler Characteristics
#==========================================================================

AC_C_CONST
AC_C_INLINE

AC_MSG_CHECKING(for STL support)
AC_LANG_PUSH(C++)
AC_TRY_COMPILE([#include <string>], [std::string str;], [HAVE_STL=1])
AC_LANG_POP(C++)
if test "x$HAVE_STL" = x1; then
   AC_MSG_RESULT(maybe)
else
   AC_MSG_RESULT(no)
   AC_MSG_ERROR([Can't build with this C++ compiler.  You may want to install gcc-3.0 on your system and pass the CC=gcc-3.0 CXX=g++-3.0 arguments to configure.])
fi

AC_MSG_CHECKING(for GCC 2.x STL namespace bugs)
AC_LANG_PUSH(C++)
AC_TRY_COMPILE([#include <string>], [string str;], [OLD_GCC=1])
AC_LANG_POP(C++)
if test "x$OLD_GCC" = x1; then
   AC_MSG_RESULT(yes)
   AC_MSG_ERROR([Can't build with this C++ compiler.  You may want to install gcc-3.0 on your system and pass the CC=gcc-3.0 CXX=g++-3.0 arguments to configure.])
else
   AC_MSG_RESULT(no)
fi


#==========================================================================
# Checks for library functions.
#==========================================================================

AC_CHECK_FUNCS([strstr])


#==========================================================================
# Output
#==========================================================================

# Some of our libraries also require configuration.
AC_CONFIG_SUBDIRS(libs/plt/src)

# Output our results.
AC_OUTPUT([Makefile libs/Makefile libs/crypto/Makefile Common/Makefile Common/fonttools/Makefile wx/Makefile wx/src/Makefile])