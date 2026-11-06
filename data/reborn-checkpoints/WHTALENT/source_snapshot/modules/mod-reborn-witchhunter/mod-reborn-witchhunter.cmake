# WHFIX1A: executed by modules/CMakeLists.txt in the correct source-property scope.
set_property(SOURCE "${CMAKE_CURRENT_LIST_DIR}/src/RebornWitchHunterTalents.cpp"
    APPEND PROPERTY COMPILE_DEFINITIONS REBORN_WH_TALENT_BUILD=20261105)
