AC_ADD_SCRIPT("${CMAKE_CURRENT_LIST_DIR}/src/RebornWitchDoctor.cpp")
AC_ADD_SCRIPT_LOADER("RebornWitchDoctor" "${CMAKE_CURRENT_LIST_DIR}/src/loader.h")

AC_ADD_SCRIPT("${CMAKE_CURRENT_LIST_DIR}/src/RebornWitchDoctorTalents.cpp")
AC_ADD_SCRIPT_LOADER("RebornWitchDoctorTalent" "${CMAKE_CURRENT_LIST_DIR}/src/talent_loader.h")

AC_ADD_CONFIG_FILE("${CMAKE_CURRENT_LIST_DIR}/conf/RebornWitchDoctor.conf.dist")
