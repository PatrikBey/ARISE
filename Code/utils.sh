#!/bin/bash
#
#
# # utils.sh
#
#
# | ARISE | Automated Regions of Interest Streamline Extraction | 
# | Version | 0.1 |
#
# | Author | Bey, Patrik |
# | Affiliation | Queen Square Institute of Neurology, University College London |
# | Email | patrik.bey@ucl.ac.uk |
#
# | last update | 2025.07.29 |
#
#
#
# | Description |
#   This script contains utility functions
#   utilized within the ARISE pipeline.
#
# FUNCTIONS:
#
# 1. show_usage
# 2. log_msg
# 3. get_file_count
# 4. get_temp_dir
# 5. progress_bar
# 6. contains_string
# 7. get_dim_info







# ---- 1. show_usage ---- #

show_usage() {
    figlet "| ARISE |" | lolcat 

    echo "| ARISE | Automated Regions of Interest Streamline Extraction
          author:       Patrik Bey
          last update:  2026/01/10" | lolcat

    cat <<EOF

    --- usage ---

    docker run \
        -v /PATH/TO/STUDYFOLDER:/data \
        -e seed="SeedROIs" \
        -e target="TargetROIs" \
        roi2roi

    --- variables ---

    <<seed>>        name of set of ROIs to use as initial ROIs for connectivity
                        {required} | [represents rows in conenctivity matrix]

    <<target>>      name of set of ROIs to use as secondary ROIs 
                    for connectivity
                        {optional} | [represents columns in connectivity matrix]

    <<tracts>>      tract file path relative to /data
                        {optional} | [default: dTOR_full_tractogram.tck (Elias et al. (2024))]
    
    <<atlas>>       Atlas name to use for connectome preparation.
                        {optional} | [default: AAL3]

    <<cleanup>>         boolean whether to remove temporary files
                        {optional} | [default: True]

    --- input ---

    | DISCONNECTOME |

    /STUDYFOLDER/
    ├── ROIMASK.nii.gz



    | ROI2ROI |

    /STUDYFOLDER/
    ├── SeedROIs/
    │   ├── masks/
    │   │   ├── mask1.nii.gz
    │   │   ├── mask2.nii.gz
    │   │   └── ...
    └── TargetROIs/
        ├── masks/
        │   ├── mask1.nii.gz
        │   ├── mask2.nii.gz
        │   └── ...

EOF

exit 1
}


# ---- 2. log_msg ---- #
log_msg() {
    # print out text for logging
    _type=$( echo ${1} | cut -d'|' -f1 )
    _message=${1}
    if [[ ${CLUSTER,,} = "true" ]]; then
        echo -e "\n$(date) $(basename  -- "$0") | ${_message}"
    else
        if [[ ${_type,,} = "start " ]] || [[ ${_type,,} = "finished " ]] || [[ ${_type,,} = "error " ]] || [[ ${_type,,} = "warning " ]]; then
            echo -e "\n$(date) $(basename  -- "$0") | ${_message}" | lolcat
        else
            echo -e "\n$(date) $(basename  -- "$0") | ${_message}"
        fi
    fi
}

# ---- 3. get_file_count ---- #
get_file_count() {
    # return number of files in
    # file list variable
    export filecount=$( echo ${1} | wc -w )
}

# ---- 4. get_temp_dir ---- #
get_temp_dir(){
# create temporary directory
    randID=$RANDOM
    export TempDir="${1}/temp-${randID}"
    mkdir ${TempDir}
}

# ---- 5. progress_bar ---- #
progress_bar() {
    # print a progress bar during loops
    # ${1} current iteration of loop
    # ${2} total length of loop
    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*4)/10
    let _left=40-$_done
    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")
    printf "\rProgress : [${_fill// /#}${_empty// /-}] ${_progress}%%"
}

# ---- 6. contains_string ---- #
contains_string() {
    # check if string contains substring
    # ${1} string to check
    # ${2} substring to check for
    if [[ ${1,,} == *"${2,,}"* ]]; then
        echo "TRUE"
    else
        echo "FALSE"
    fi
}

# ---- 7. get_dim_info ---- #
GetDimInfo () {
# get image dimension from input header
# and return as $ImgDim
    _dim1="$( fslval ${1} dim1)"
    len1="$((${#_dim1}-1))"
    _dim2="$( fslval ${1} dim2)"
    len2="$((${#_dim2}-1))"
    _dim3="$( fslval ${1} dim3)"
    len3="$((${#_dim3}-1))"
    export ImgDim=${_dim1:0:${len1}}"x"${_dim2:0:${len2}}"x"${_dim3:0:${len3}}
}
