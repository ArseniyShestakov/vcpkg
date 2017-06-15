include(vcpkg_common_functions)

find_program(GIT git)
vcpkg_acquire_depot_tools(DEPOT_TOOLS)
vcpkg_find_acquire_program(PYTHON2)
vcpkg_find_acquire_program(NINJA)

set(GIT_URL "https://chromium.googlesource.com/angle/angle.git")
set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/angle.git)
set(GCLIENT ${DEPOT_TOOLS}/gclient.bat)

file(REMOVE_RECURSE ${CURRENT_BUILDTREES_DIR})
file(MAKE_DIRECTORY ${CURRENT_BUILDTREES_DIR})

get_filename_component(PYTHON_DIRECTORY ${PYTHON2} DIRECTORY)
get_filename_component(GIT_DIRECTORY ${GIT} DIRECTORY)

set(VCPKG_PLATFORM_TOOLSET v140)
set(MSVS_VERSION 2015)

if (TRIPLET_SYSTEM_ARCH MATCHES "x64")
  set(APPEND_ARCH "_x64")
else ()
  set(APPEND_ARCH "")
endif()



set(DEBUG_PATH "${SOURCE_PATH}/out/Debug${APPEND_ARCH}")
set(RELEASE_PATH "${SOURCE_PATH}/out/Release${APPEND_ARCH}")

SET(ENV{PATH} "${GIT_DIRECTORY};${PYTHON_DIRECTORY};${PYTHON_DIRECTORY}/scripts;${DEPOT_TOOLS};$ENV{PATH};")
SET(ENV{GYP_MSVS_VERSION} "${MSVS_VERSION}")
SET(ENV{GYP_GENERATORS} "ninja")

if (VCPKG_CMAKE_SYSTEM_NAME STREQUAL WindowsStore)
  SET(ENV{GYP_GENERATE_WINRT} "1")
endif()

if(NOT EXISTS "${DOWNLOADS}/angle.git")
  message(STATUS "Cloning")
  vcpkg_execute_required_process(
    COMMAND ${GIT} clone ${GIT_URL} ${DOWNLOADS}/angle.git
    WORKING_DIRECTORY ${DOWNLOADS}
    LOGNAME git-clone
  )
else()
  message(STATUS "Pulling")
  vcpkg_execute_required_process(
    COMMAND ${GIT} pull ${GIT_URL}
    WORKING_DIRECTORY ${DOWNLOADS}/angle.git
    LOGNAME git-pulling
  )
endif()



file(COPY ${DOWNLOADS}/angle.git DESTINATION ${CURRENT_BUILDTREES_DIR})

message(STATUS "gclient config")
vcpkg_execute_required_process(
  COMMAND ${GCLIENT} config  ${GIT_URL}
  WORKING_DIRECTORY  ${SOURCE_PATH}
  LOGNAME gclient-config
)
message(STATUS "gclient config done")

message(STATUS "gclient sync")

vcpkg_execute_required_process(
  COMMAND ${GCLIENT} sync
  WORKING_DIRECTORY  ${SOURCE_PATH}
  LOGNAME gclient-sync
)
message(STATUS "gclient sync done")

message(STATUS "gclient runhooks")


vcpkg_execute_required_process(
  COMMAND ${GCLIENT} runhooks
  WORKING_DIRECTORY  ${SOURCE_PATH}
  LOGNAME gclient-runhooks
)
message(STATUS "gclient runhooks done")

message(STATUS "Building ${RELEASE_PATH} for Release")
vcpkg_execute_required_process(
  COMMAND ${NINJA} -C ${RELEASE_PATH}
  WORKING_DIRECTORY  ${SOURCE_PATH}
  LOGNAME build-${TARGET_TRIPLET}-rel
)

message(STATUS "Building ${DEBUG_PATH} for Debug")
vcpkg_execute_required_process(
  COMMAND ${NINJA} -C ${DEBUG_PATH}
  WORKING_DIRECTORY  ${SOURCE_PATH}
  LOGNAME build-${TARGET_TRIPLET}-dbg
)



file(GLOB DLLS
  "${RELEASE_PATH}/*.dll"
  "${RELEASE_PATH}/Release/*.dll"
  "${RELEASE_PATH}/*/Release/*.dll"
)
file(GLOB LIBS
  "${RELEASE_PATH}/*.lib"
  "${RELEASE_PATH}/Release/*.lib"
  "${RELEASE_PATH}/*/Release/*.lib"
)
file(GLOB DEBUG_DLLS
  "${DEBUG_PATH}/*.dll"
  "${DEBUG_PATH}/Debug/*.dll"
  "${DEBUG_PATH}/*/Debug/*.dll"
)
file(GLOB DEBUG_LIBS
  "${DEBUG_PATH}/*.lib"
  "${DEBUG_PATH}/Debug/*.lib"
  "${DEBUG_PATH}/*/Debug/*.lib"
)
file(GLOB HEADERS
  ${SOURCE_PATH}/include/*
)

if(DLLS)
  file(INSTALL ${DLLS} DESTINATION ${CURRENT_PACKAGES_DIR}/bin)
endif()
file(INSTALL ${LIBS} DESTINATION ${CURRENT_PACKAGES_DIR}/lib)
if(DEBUG_DLLS)
  file(INSTALL ${DEBUG_DLLS} DESTINATION ${CURRENT_PACKAGES_DIR}/debug/bin)
endif()
file(INSTALL ${DEBUG_LIBS} DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib)
file(INSTALL ${HEADERS} DESTINATION ${CURRENT_PACKAGES_DIR}/include )
file(INSTALL ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/angle RENAME copyright)

file(GLOB REMOVE_DLLS
  "${CURRENT_PACKAGES_DIR}/bin/d3dcompiler_47.dll"
  "${CURRENT_PACKAGES_DIR}/bin/msvcrt.dll"
  "${CURRENT_PACKAGES_DIR}/debug/bin/d3dcompiler_47.dll"
  "${CURRENT_PACKAGES_DIR}/debug/bin/msvcrt.dll"
)
file(REMOVE ${REMOVE_DLLS})
vcpkg_copy_pdbs()
