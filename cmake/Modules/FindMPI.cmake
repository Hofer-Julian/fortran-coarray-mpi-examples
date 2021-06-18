# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

#[=======================================================================[.rst:
FindMPI
-------

by Michael Hirsch www.scivision.dev

Finds compiler flags or library necessary to use MPI library (MPICH, OpenMPI, MS-MPI, Intel MPI, ...)

Components
==========

MPI code languages are specified by components:

``C``

``Fortran``


Result Variables
^^^^^^^^^^^^^^^^

``MPI_FOUND``
  indicates MPI library found

``MPI_LIBRARIES``
  MPI library path

``MPI_INCLUDE_DIRS``
  MPI include path

#]=======================================================================]
include(CheckFortranSourceCompiles)
include(CheckCSourceCompiles)

set(CMAKE_REQUIRED_FLAGS)
set(_hints)
set(_hints_inc)


function(find_c)

# mpich: mpi pmpi
# openmpi: mpi
# MS-MPI: msmpi
# Intel Windows: impi
# Intel MPI: mpi

set(MPI_C_LIBRARY)

if(MSVC)
  set(names impi)
elseif(WIN32)
  set(names msmpi)
elseif(DEFINED ENV{I_MPI_ROOT})
  set(names mpi)
else()
  set(names mpi pmpi)
endif()

pkg_search_module(pc_mpi_c ompi-c)

find_program(c_wrap
  NAMES mpiicc mpicc
  HINTS ${_hints}
  PATH_SUFFIXES bin sbin
  NAMES_PER_DIR)
if(c_wrap)
  get_filename_component(_wrap_hint ${c_wrap} DIRECTORY)
  get_filename_component(_wrap_hint ${_wrap_hint} DIRECTORY)
endif()

foreach(n ${names})

  find_library(MPI_C_${n}_LIBRARY
    NAMES ${n}
    HINTS ${_wrap_hint} ${pc_mpi_c_LIBRARY_DIRS} ${pc_mpi_c_LIBDIR} ${_hints}
    PATH_SUFFIXES lib
  )
  if(MPI_C_${n}_LIBRARY)
    list(APPEND MPI_C_LIBRARY ${MPI_C_${n}_LIBRARY})
  endif()

endforeach()
if(NOT MPI_C_LIBRARY)
  return()
endif()

find_path(MPI_C_INCLUDE_DIR
  NAMES mpi.h
  HINTS ${_wrap_hint} ${pc_mpi_c_INCLUDE_DIRS} ${_hints} ${_hints_inc}
  PATH_SUFFIXES include
)
if(NOT MPI_C_INCLUDE_DIR)
  return()
endif()

set(CMAKE_REQUIRED_INCLUDES ${MPI_C_INCLUDE_DIR})
set(CMAKE_REQUIRED_LIBRARIES ${MPI_C_LIBRARY})
if(Threads_FOUND)
  list(APPEND CMAKE_REQUIRED_LIBRARIES Threads::Threads)
endif()
check_c_source_compiles("
#include <mpi.h>
#ifndef NULL
#define NULL 0
#endif
int main(void) {
    MPI_Init(NULL, NULL);
    MPI_Finalize();
    return 0;}
" MPI_C_links)
if(NOT MPI_C_links)
  return()
endif()

set(MPI_C_INCLUDE_DIR ${MPI_C_INCLUDE_DIR} PARENT_SCOPE)
set(MPI_C_LIBRARY ${MPI_C_LIBRARY} PARENT_SCOPE)
set(MPI_C_FOUND true PARENT_SCOPE)

endfunction(find_c)


function(find_fortran)

# mpich: mpifort mpi pmpi
# openmpi: mpi_usempif08 mpi_usempi_ignore_tkr mpi_mpifh mpi
# MS-MPI: msmpi
# Intel Windows: impi
# Intel MPI: mpifort mpi

set(MPI_Fortran_LIBRARY)

if(MSVC)
  set(names impi)
elseif(WIN32)
  set(names msmpi)
elseif(DEFINED ENV{I_MPI_ROOT})
  set(names mpifort mpi)
else()
  set(names
    mpi_usempif08 mpi_usempi_ignore_tkr mpi_mpifh mpi
    mpifort mpi pmpi
    )
endif()

pkg_search_module(pc_mpi_f ompi-fort)

find_program(f_wrap
  NAMES mpiifort mpifort mpifc
  HINTS ${_hints}
  PATH_SUFFIXES bin sbin
  NAMES_PER_DIR)
if(f_wrap)
  get_filename_component(_wrap_hint ${f_wrap} DIRECTORY)
  get_filename_component(_wrap_hint ${_wrap_hint} DIRECTORY)
endif()

foreach(n ${names})

  find_library(MPI_Fortran_${n}_LIBRARY
    NAMES ${n}
    HINTS ${_wrap_hint} ${pc_mpi_f_LIBRARY_DIRS} ${pc_mpi_f_LIBDIR} ${_hints}
    PATH_SUFFIXES lib
  )
  if(MPI_Fortran_${n}_LIBRARY)
    list(APPEND MPI_Fortran_LIBRARY ${MPI_Fortran_${n}_LIBRARY})
  endif()

endforeach()
if(NOT MPI_Fortran_LIBRARY)
  return()
endif()

find_path(MPI_Fortran_INCLUDE_DIR
  NAMES mpi.mod
  HINTS ${_wrap_hint} ${pc_mpi_f_INCLUDE_DIRS} ${_hints} ${_hints_inc}
  PATH_SUFFIXES include
)
if(NOT MPI_Fortran_INCLUDE_DIR)
  return()
endif()

find_path(MPI_Fortran_INCLUDE_EXTRA
  NAMES mpifptr.h
  HINTS ${_wrap_hint} ${pc_mpi_f_INCLUDE_DIRS} ${_hints} ${_hints_inc}
  PATH_SUFFIXES include include/x64
)

if(MPI_Fortran_INCLUDE_EXTRA AND NOT MPI_Fortran_INCLUDE_EXTRA STREQUAL ${MPI_Fortran_INCLUDE_DIR})
  list(APPEND MPI_Fortran_INCLUDE_DIR ${MPI_Fortran_INCLUDE_EXTRA})
endif()

set(CMAKE_REQUIRED_INCLUDES ${MPI_Fortran_INCLUDE_DIR})
set(CMAKE_REQUIRED_LIBRARIES ${MPI_Fortran_LIBRARY})
if(Threads_FOUND)
  list(APPEND CMAKE_REQUIRED_LIBRARIES Threads::Threads)
endif()

check_fortran_source_compiles("
program test
use mpi
implicit none
integer :: i
call mpi_init(i)
call mpi_finalize(i)
end program" MPI_Fortran_links SRC_EXT F90)
if(NOT MPI_Fortran_links)
  return()
endif()

set(MPI_Fortran_INCLUDE_DIR ${MPI_Fortran_INCLUDE_DIR} PARENT_SCOPE)
set(MPI_Fortran_LIBRARY ${MPI_Fortran_LIBRARY} PARENT_SCOPE)
set(MPI_Fortran_FOUND true PARENT_SCOPE)

endfunction(find_fortran)

#===== main program ======

find_package(PkgConfig)
find_package(Threads)

# Intel MPI, which works with non-Intel compilers on Linux
if(CMAKE_SYSTEM_NAME STREQUAL Linux OR CMAKE_C_COMPILER_ID MATCHES Intel)
  list(APPEND _hints $ENV{I_MPI_ROOT})
endif()

if(WIN32)
  list(APPEND _hints $ENV{MSMPI_LIB64})
  list(APPEND _hints_inc $ENV{MSMPI_INC})
endif()

# must have MPIexec to be worthwhile (MS-MPI doesn't have mpirun, but all have mpiexec)
find_program(_exec
  NAMES mpiexec
  HINTS ${_hints} $ENV{MSMPI_BIN}
  PATH_SUFFIXES bin sbin
)


if(C IN_LIST MPI_FIND_COMPONENTS)
  find_c()
endif()

if(Fortran IN_LIST MPI_FIND_COMPONENTS)
  find_fortran()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(MPI
  REQUIRED_VARS _exec
  HANDLE_COMPONENTS)

if(MPI_C_FOUND)
  set(MPI_C_LIBRARIES ${MPI_C_LIBRARY})
  set(MPI_C_INCLUDE_DIRS ${MPI_C_INCLUDE_DIR})
  if(NOT TARGET MPI::MPI_C)
    add_library(MPI::MPI_C IMPORTED UNKNOWN)
    set_target_properties(MPI::MPI_C PROPERTIES
      IMPORTED_LOCATION "${MPI_C_LIBRARIES}"
      INTERFACE_INCLUDE_DIRECTORIES "${MPI_C_INCLUDE_DIRS}"
    )
  endif()
endif(MPI_C_FOUND)

if(MPI_Fortran_FOUND)
  set(MPI_Fortran_LIBRARIES ${MPI_Fortran_LIBRARY})
  set(MPI_Fortran_INCLUDE_DIRS ${MPI_Fortran_INCLUDE_DIR})
  if(NOT TARGET MPI::MPI_Fortran)
    add_library(MPI::MPI_Fortran IMPORTED UNKNOWN)
    set_target_properties(MPI::MPI_Fortran PROPERTIES
      IMPORTED_LOCATION "${MPI_Fortran_LIBRARIES}"
      INTERFACE_INCLUDE_DIRECTORIES "${MPI_Fortran_INCLUDE_DIRS}"
    )
  endif()

endif(MPI_Fortran_FOUND)

if(MPI_FOUND)
  set(MPI_LIBRARIES ${MPI_Fortran_LIBRARIES} ${MPI_C_LIBRARIES})
  set(MPI_INCLUDE_DIRS ${MPI_Fortran_INCLUDE_DIRS} ${MPI_C_INCLUDE_DIRS})
endif()
