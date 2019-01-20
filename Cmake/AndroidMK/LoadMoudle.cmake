SET(LOAD_MOUDLE_DEBUG OFF)
SET(MK_OUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/AndroidMK")
SET(MK_DEP_DIR "${MK_OUT_DIR}/dep")

function(paresPath in out)
    string(REGEX REPLACE " +|\"|\\[|\\]" "" paresPath_tmp ${in})
    string(REGEX REPLACE ":{.*" "" paresPath_name ${paresPath_tmp})
    string(REGEX REPLACE ".*path:" "" paresPath_tmp ${paresPath_tmp})
    string(REGEX REPLACE ",.*" "" paresPath_path ${paresPath_tmp})
    if(LOAD_MOUDLE_DEBUG)
        message("paresPath: name = ${name}")
        message("paresPath: path = ${path}")
    endif()
    SET(${out} "${paresPath_name}:${paresPath_path}" PARENT_SCOPE)
endfunction()

function(getMoudlePath type module out)
    SET(getMoudlePath_module_path "")
    file(STRINGS ${MK_OUT_DIR}/${type}.module getMoudlePath_module_paths REGEX "^${module}:.*")
    foreach(getMoudlePath_path ${getMoudlePath_module_paths})
        if(LOAD_MOUDLE_DEBUG)
            message("getModlePath: ${type} = ${getMoudlePath_path}")
        endif()
        string(REPLACE ":" ";" getMoudlePath_path ${getMoudlePath_path})
        LIST(GET getMoudlePath_path 1 getMoudlePath_path)
        SET(getMoudlePath_module_path ${getMoudlePath_path})
    endforeach()
    SET(${out} "${getMoudlePath_module_path}" PARENT_SCOPE)
endfunction()

function(containsMoudle name out)
    SET(${out} OFF PARENT_SCOPE)
    if(EXISTS ${MK_OUT_DIR}/module.list)
        file(STRINGS ${MK_OUT_DIR}/module.list containsMoudle_module_list REGEX "^${name}:")
        foreach(containsMoudle_module_path ${containsMoudle_module_list})
            # TODO
            SET(${out} ON PARENT_SCOPE)
        endforeach()
    endif()
endfunction()

function(containsDependencies moudle type name out)
    SET(${out} OFF PARENT_SCOPE)
    if(EXISTS ${MK_DEP_DIR}/${moudle}.dep)
        file(STRINGS ${MK_DEP_DIR}/${moudle}.dep containsDependencies_list REGEX "^${name}:${type}")
        foreach(containsDependencies ${containsDependencies_list})
            # TODO
            SET(${out} ON PARENT_SCOPE)
        endforeach()
    endif()
endfunction()

function(getMoudleDependencies moudle out)
    SET(${out} "" PARENT_SCOPE)
    if(EXISTS ${MK_DEP_DIR}/${moudle}.dep)
        file(STRINGS ${MK_DEP_DIR}/${moudle}.dep getMoudleDependencies_list)
        set(${out} "${getMoudleDependencies_list}" PARENT_SCOPE)
    endif()
endfunction()

function(doMoudleDependencies moudle)
    getMoudleDependencies("${moudle}" doMoudleDependencies_list)
    foreach(doMoudleDependencies_moudle ${doMoudleDependencies_list})
        string(REPLACE ":" ";" doMoudleDependencies_moudle "${doMoudleDependencies_moudle}")
        LIST(GET doMoudleDependencies_moudle 0 doMoudleDependencies_name)
        LIST(GET doMoudleDependencies_moudle 1 doMoudleDependencies_type)
        parseAndroidMK("${doMoudleDependencies_name}" "${doMoudleDependencies_type}")
    endforeach()
endfunction()

####### save someing #######

function(addMoudleDependencies moudle type dependency)
    containsDependencies("${moudle}" "${type}" "${dependency}" addMoudleDependencies_is_add)
    if(NOT addMoudleDependencies_is_add)
        file(APPEND ${MK_DEP_DIR}/${moudle}.dep "${dependency}:${type}\n")
    endif()
endfunction()

function(addMoudle name path)
    file(APPEND ${MK_OUT_DIR}/module.list "${name}:${path}\n")
endfunction()

function(loadMoudle )
    parseInit()
    SET(loadMoudle_shared_file_path ${MK_OUT_DIR}/${MK_SHARED}.module)
    SET(loadMoudle_static_file_path ${MK_OUT_DIR}/${MK_STATIC}.module)

    if(NOT EXISTS ${loadMoudle_shared_file_path})
        set(loadMoudle_need ON)
    endif()
    if(NOT EXISTS ${loadMoudle_static_file_path})
        set(loadMoudle_need ON)
    endif()
    if(loadMoudle_need)
        file(REMOVE ${loadMoudle_shared_file_path})
        file(REMOVE ${loadMoudle_static_file_path})
    else()
        return()
    endif()

    message("loadMoudle start")
    file(STRINGS ${PROJECT_DIR}/out/target/product/${ANDROID_LUNCH}/module-info.json MyFile REGEX ".*(SHARED_LIBRARIES|STATIC_LIBRARIES).*")
    foreach(line ${MyFile})
        string(STRIP "${line}" line)
        paresPath("${line}" loadMoudle_line)
        if( "${line}" MATCHES ".*STATIC_LIBRARIES.*")
            file(APPEND ${loadMoudle_static_file_path} "${loadMoudle_line}\n")
        endif()
        if( "${line}" MATCHES ".*SHARED_LIBRARIES.*")
            file(APPEND ${loadMoudle_shared_file_path} "${loadMoudle_line}\n")
        endif()
    endforeach()
endfunction()

function(parseInit)
    file(REMOVE ${MK_OUT_DIR}/module.list)
    file(REMOVE_RECURSE ${MK_DEP_DIR})
endfunction()