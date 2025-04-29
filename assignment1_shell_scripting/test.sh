run_cpp_with_input() {
    local cpp_file="$1"
    local input_file="$2"

    local dir
    dir=$(dirname "$cpp_file")
    local base
    base=$(basename "$cpp_file" .cpp)
    local abs_input_file
    abs_input_file=$(realpath "$input_file")

    local input_filename
    input_filename=$(basename "$input_file")
    local output_text="${input_filename: -5:1}"

    pushd "$dir" > /dev/null || return

    g++ "$base.cpp" -o "$base.out"
    ./"$base.out" < "$abs_input_file" > "out${output_text}.txt"

    popd > /dev/null
}

run_c_with_input() {
    local c_file="$1"
    local input_file="$2"

    local dir
    dir=$(dirname "$c_file")
    local base
    base=$(basename "$c_file" .c)
    local abs_input_file
    abs_input_file=$(realpath "$input_file")

    local input_filename
    input_filename=$(basename "$input_file")
    local output_text="${input_filename: -5:1}"  # e.g., gets '1' from 'test1.txt'

    pushd "$dir" > /dev/null || return

    gcc "$base.c" -o "$base.out"
    ./"$base.out" < "$abs_input_file" > "out${output_text}.txt"

    popd > /dev/null
}

run_java_with_input() {
    local java_file="$1"
    local input_file="$2"

    local dir
    dir=$(dirname "$java_file")
    local base
    base=$(basename "$java_file" .java)
    local abs_input_file
    abs_input_file=$(realpath "$input_file")

    local input_filename
    input_filename=$(basename "$input_file")
    local output_text="${input_filename: -5:1}"

    pushd "$dir" > /dev/null || return

    javac "$base.java"
    java "$base" < "$abs_input_file" > "out${output_text}.txt"

    popd > /dev/null
}

run_py_with_input() {
    local py_file="$1"
    local input_file="$2"

    local dir
    dir=$(dirname "$py_file")
    local base
    base=$(basename "$py_file")
    local abs_input_file
    abs_input_file=$(realpath "$input_file")

    local input_filename
    input_filename=$(basename "$input_file")
    local output_text="${input_filename: -5:1}"

    pushd "$dir" > /dev/null || return

    python3 "$base" < "$abs_input_file" > "out${output_text}.txt"

    popd > /dev/null
}




run_py_with_input "./Shell-Scripting-Assignment-Files/My_match/Python/2105219/main.py" "./Shell-Scripting-Assignment-Files/Workspace/tests/test4.txt"

string=test1
echo "${string: -1:1}"