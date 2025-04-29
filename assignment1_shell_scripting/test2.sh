#!/bin/bash

# functions
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


# extracting commamd line arguments
len=$#
total_arg=$@
args=("$@")

submission=$1
target=$2
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

echo "flag status"
echo "-v : $is_v"
echo "-noexecute : $is_noexecute"
echo "-nolc : $is_nolc"
echo "-nocc : $is_nocc"
echo "-nofc : $is_nofc"

# implementing tasks

unzip="./unzipped"
temp_source_code="./source_code"

for i in "$submission"/*.zip; do
    # Task A
    echo ""

    echo "unzipping: $i"
    filename=$(basename "$i" .zip)
    id="${filename:(-7):7}"
    mkdir -p "$unzip/$filename" # this is a temporary folder
    unzip -qq "$i" -d "$unzip/$filename"

    echo "copying source code to a temp folder"
    mkdir -p "$temp_source_code" # this is a temporary folder
    find "$unzip/$filename" -type f \( -name "*.c" -o -name "*.cpp" -o -name "*.py" -o -name "*.java" \) -exec cp {} "$temp_source_code" \;

    echo "creating and copying source code to target folder from the temp folder"
    j=$(find "$temp_source_code" -type f)
    extension="${j##*.}"
    if [ "$extension" == "cpp" ]; then
        capitalized="C++"
        main="main"
    elif [ "$extension" == "py" ]; then
        capitalized="Python"  
        main="main"  
    elif [ "$extension" == "java" ]; then
        capitalized="${extension^}"
        main="Main"
    else
        capitalized="${extension^}"
        main="main"
    fi
    new_file="$temp_source_code/$main.$extension"
    mv -f "$j" "$new_file"
    mkdir -p "$target/$capitalized/$id"
    cp "$new_file" "$target/$capitalized/$id"
    rm "$new_file"

    # Task B
    echo "getting code metrics"
    lineCount=$(get_line_count "$target/$capitalized/$id/main.$extension")
    echo "line count is : $lineCount"
    commentCount=$(get_comment_count "$target/$capitalized/$id/main.$extension")
    echo "commnet count is : $commentCount"
    countFunc=$(get_function_count "$target/$capitalized/$id/main.$extension")
    echo "Function count is : $countFunc"

done

echo "removing the $unzip folder"
rm -rf $unzip
echo "removing the temp_source_code folder"
rm -rf "$temp_source_code"

# ./organize.sh ./Shell-Scripting-Assignment-Files/Workspace/submissions ./Shell-Scripting-Assignment-Files/My_match/ ./Shell-Scripting-Assignment-Files/Workspace/tests ./Shell-Scripting-Assignment-Files/Workspace/answers
