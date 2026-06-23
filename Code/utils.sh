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
# | last update | 2026.06.23 |
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
          last update:  2026/06/23" | lolcat

    cat <<EOF

    --- usage ---

    docker run \
        -v /PATH/TO/STUDYFOLDER:/data \
        -e Seed="ROIMASK.nii.gz" \
        arise:0.5

    --- variables ---

    <<Seed>>        {required}
                    seed input — three accepted forms:
                      - single NIfTI mask file relative to /data
                            → disconnectome mode
                            e.g. -e Seed="lesion.nii.gz"
                      - directory (relative to /data) containing a masks/ subfolder
                            → ROI2ROI mode
                            e.g. -e Seed="SeedROIs"
                      - comma-separated list of ROI names
                            → ROI2ROI mode
                            e.g. -e Seed="ROI1,ROI2"

    <<Target>>      {optional} [default: same as Seed]
                    target ROI set for ROI2ROI connectivity.
                    accepts a directory or comma-separated list (same as Seed).
                    ignored in disconnectome mode.

    <<Atlas>>       {optional} [default: AAL3v1]
                    atlas name, or comma-separated list of atlas names,
                    for disconnectome extraction.
                    each name must match a <name>.nii.gz file in the
                    container template directory or in /data.
                    a separate labelled .tsv is produced per atlas.
                    e.g. -e Atlas="AAL3v1,HCPex,Schaefer2018-400"

    <<Tracts>>      {optional} [default: dTOR_2m_tractogram.tck (Elias et al. 2024)]
                    path to a custom tractogram file, relative to /data.
                    e.g. -e Tracts="sub-01/tractogram.tck"

    <<OutDir>>      {optional} [default: /data/arise]
                    output directory path inside the container.
                    e.g. -e OutDir="/data/arise/sub-01"

    <<tck_keep>>    {optional} [default: True]
                    set to False to delete the intermediate tract subset
                    file after disconnectome extraction.

    <<NOCLEANUP>>   {optional} [default: unset]
                    set to any value to retain the temporary working
                    directory after the pipeline completes.
                    e.g. -e NOCLEANUP=1

    <<CLUSTER>>     {optional} [default: unset]
                    set to "true" to suppress coloured log output,
                    suitable for cluster / HPC environments.
                    e.g. -e CLUSTER="true"
                        

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
