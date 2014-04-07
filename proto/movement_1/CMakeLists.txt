project(movement_1)

cmake_minimum_required(VERSION 2.8)

find_package( OpenCV REQUIRED )

add_executable(movement_1 main.cpp)
add_executable(movement_2 segmentator.cpp)

install(TARGETS movement_1 RUNTIME DESTINATION bin)

target_link_libraries(movement_1 ${OpenCV_LIBS} )
target_link_libraries(movement_2 ${OpenCV_LIBS} )
