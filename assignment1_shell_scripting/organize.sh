#!/bin/bash
################################################### extracting commamd line arguments
len=$#
total_arg=$@
args=("$@")

if (( len < 4 )); then 
    echo ""
    echo "Mandatory arguments are (in order) :"
    echo "path_of_zip_submissions"
    echo "path_of_target"
    echo "path_of_test"
    echo "path_of_answer"
    echo ""
    echo "optional arguments are :"
    echo "-v : prints different work processes"
    echo "-noexecute : doesn't execute the source codes"
    echo "-nolc : doesn't count and show the number of lines in source code"
    echo "-nocc : doesn't count and show the number of single line commnets in source code"
    echo "-nofc : doesn't count and show the number of functions in source code"
    exit 1
fi

submission=$1
target=$2
# target="$2/targets"
test=$3
answer=$4

flags=()
for (( i=4; i<len; i++ )); do
    flags+=("${args[$i]}")
done

is_v="0"
is_noexecute="0"
is_nolc="0"
is_nocc="0"
is_nofc="0"
for i in "${flags[@]}"; do
    if [ "$i" == "-v" ]; then
        is_v="1"
    elif [ "$i" == "-noexecute" ]; then
        is_noexecute="1"
    elif [ "$i" == "-nolc" ]; then
        is_nolc="1"
    elif [ "$i" == "-nocc" ]; then
        is_nocc="1"
    elif [ "$i" == "-nofc" ]; then
        is_nofc="1"
    fi
done

################################################### functions
print_array() {
    for element in "$@"; do
        echo "$element"
    done
}

get_line_count() {
    local file="$1"
    wc -l < "$file"
}

get_comment_count() {
    local file="$1"
    local extension="${file##*.}"
    local count=0

    if [ "$extension" = "c" ] || [ "$extension" = "cpp" ] || [ "$extension" = "java" ]; then
        count=$(grep -cE '//+' "$file")
    elif [ "$extension" = "py" ]; then
        count=$(grep -cE '#' "$file")
    else
        count=0
    fi

    echo "$count"
}

get_function_count() {
    local file="$1"
    local extension="${file##*.}"
    local count=0

    if [ "$extension" = "c" ] || [ "$extension" = "cpp" ]; then
        count=$(grep -E '^\s*(int|double|float|char|char\s*\*|string|void|bool)\s+[a-zA-Z_][a-zA-Z0-9_]*\s*\(.*\)\s*' "$file" | wc -l)

    elif [ "$extension" = "java" ]; then
        count=$(grep -E '^\s*(public|private|protected)?\s+(static)?\s*(int|double|float|char|void|boolean|long|short|byte|char)\s+[a-zA-Z_][a-zA-Z0-9_]*\s*\(.*\)\s*' "$file" | wc -l)

    elif [ "$extension" = "py" ]; then
        count=$(grep -E '^\s*def\s+[a-zA-Z_][a-zA-Z0-9_]*\s*\(.*\)\s*:' "$file" | wc -l)   

    else
        count=0
    fi

    echo "$count"
}

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
    local output_text="${input_filename: -5:1}"

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

count_txt_files() {
    local path="$1"      
    local count=0

    for i in "$path"/*.txt; do
        [ -e "$i" ] || continue
        ((count++))
    done

    echo "$count"
}

match_output() {
    local out="$1"    
    local answer="$2"  
    local matched=0

    for i in "$answer"/ans*.txt; do
        number=$(basename "$i" .txt)
        number=${number:3}

        ans_file="$i"
        out_file="$out/out$number.txt"

        if [ -f "$out_file" ]; then
            if diff -q "$ans_file" "$out_file" > /dev/null; then
                ((matched++))
            fi
        fi
    done

    echo "$matched"
}

generate_report_header() {
    local csv_file="$target/result.csv"

    mkdir -p "$target"

    if [ ! -f "$csv_file" ]; then
        header="student_id,student_name,language"
        if [ "$is_noexecute" -eq 0 ]; then
            header+=",matched,not_matched"
        fi
        if [ "$is_nolc" -eq 0 ]; then
            header+=",line_count"
        fi
        if [ "$is_nocc" -eq 0 ]; then
            header+=",comment_count"
        fi
        if [ "$is_nofc" -eq 0 ]; then
            header+=",function_count"
        fi
        echo "$header" > "$csv_file"
    fi
}

generate_report() {
    local id="$1"
    local name="$2"
    local extension="$3"
    local matched="$4"
    local mismatched="$5"
    local lineCount="$6"
    local commentCount="$7"
    local functionCount="$8"

    local csv_file="$target/result.csv"

    row="$id,\"$name\",$extension"
    if [ "$is_noexecute" -eq 0 ]; then
        row+=",$matched,$mismatched"
    fi
    if [ "$is_nolc" -eq 0 ]; then
        row+=",$lineCount"
    fi
    if [ "$is_nocc" -eq 0 ]; then
        row+=",$commentCount"
    fi
    if [ "$is_nofc" -eq 0 ]; then
        row+=",$functionCount"
    fi

    echo "$row" >> "$csv_file"
}


################################################### implementing tasks
unzip="./unzipped"
temp_source_code="./source_code"

if [ -d "$target" ]; then
    rm -r "$target"
fi
generate_report_header

for i in "$submission"/*.zip; do
    # extract information from file 
    filename=$(basename "$i" .zip)
    id="${filename:(-7):7}"
    studentName=${filename:0:-27}

    if [ "$is_v" -eq 1 ]; then
        echo "Organizing files of $id"
    fi

    # create a temporary folder and unzip there
    mkdir -p "$unzip/$filename"
    unzip -qq "$i" -d "$unzip/$filename"

    # create another temporary folder and copy the source code from the unzip folder
    mkdir -p "$temp_source_code"
    find "$unzip/$filename" -type f \( -name "*.c" -o -name "*.cpp" -o -name "*.py" -o -name "*.java" \) -exec cp {} "$temp_source_code" \;

    # find the source code and extract file type
    j=$(find "$temp_source_code" -type f)
    extension="${j##*.}"

    # prepare file name and destination folder
    if [ "$extension" == "cpp" ]; then
        capitalized="C++"
        main="main"
    elif [ "$extension" == "java" ]; then
        capitalized="Java"
        main="Main"
    elif [ "$extension" == "c" ]; then
        capitalized="C"
        main="main"        
    else 
        capitalized="Python"
        main="main"
    fi

    # rename source code
    new_file="$temp_source_code/$main.$extension"
    if [ "$j" != "$new_file" ]; then
        mv -f "$j" "$new_file"
    fi

    # move the source code to target folder 
    mkdir -p "$target/$capitalized/$id"
    cp "$new_file" "$target/$capitalized/$id"
    rm "$new_file"

    # get line count , comment count , function count of source code
    lineCount="0"
    commentCount="0"
    functionCount="0"
    if [ "$is_nolc" -eq 0 ]; then
        lineCount=$(get_line_count "$target/$capitalized/$id/$main.$extension")
    fi
    if [ "$is_nocc" -eq 0 ]; then
        commentCount=$(get_comment_count "$target/$capitalized/$id/$main.$extension")
    fi
    if [ "$is_nofc" -eq 0 ]; then
        countFunc=$(get_function_count "$target/$capitalized/$id/$main.$extension")
    fi

    # execute source code for each test case
    if [ "$is_noexecute" -eq 0 ]; then

        if [ "$is_v" -eq 1 ]; then
            echo "Executing files of $id"
        fi

        for j in "$test"/*.txt; do
            if [ "$extension" == "cpp" ]; then
                run_cpp_with_input "$target/$capitalized/$id/main.cpp" "$j"
            elif [ "$extension" == "py" ]; then
                run_py_with_input "$target/$capitalized/$id/main.py" "$j"
            elif [ "$extension" == "java" ]; then
                run_java_with_input "$target/$capitalized/$id/Main.java" "$j"
            else
                run_c_with_input "$target/$capitalized/$id/main.c" "$j"
            fi
        done
    fi

    # get matched and unmatched count
    total_test=$(count_txt_files "$answer")
    output_matched=$(match_output "$target/$capitalized/$id" "$answer")
    output_mismatched=$((total_test - output_matched))

    # generate report
    generate_report "$id" "$studentName" "$capitalized" "$output_matched" "$output_mismatched" "$lineCount" "$commentCount" "$countFunc"

done


if [ "$is_v" -eq 1 ]; then
    echo "All submissions processed successfully"
fi
# delete temporary folders
rm -rf $unzip
rm -rf "$temp_source_code"



# ./organize.sh ./Shell-Scripting-Assignment-Files/Workspace/submissions ./hey ./Shell-Scripting-Assignment-Files/Workspace/tests ./Shell-Scripting-Assignment-Files/Workspace/answers
