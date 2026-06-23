#!/bin/bash
#
#
# # functions.sh
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
#   This script contains processing functions
#   utilized within the ARISE pipeline.
#
# FUNCTIONS:
#
# 1. get_parcellation
# 2. get_tract_mask
# 3. create_full_parc
# 4. get_subset_sc
# 5. get_full_sc
# 6. get_lut
# 7. add_lut_sc





# ---- 1. get_parcellation ---- #

# get_parcellation() {
#     #
#     # $1 input file list name || e.g. ${Seed}
#     #
#     file_list=$(ls "${Path}/${1}/masks")
#     get_file_count "${file_list}"
#     cp ${TEMPLATEDIR}/Atlas/Empty.nii.gz "${TempDir}/${1}_parc.nii.gz"

#     touch ${OutDir}/${1}/lut.txt
#     echo "ID ROI" >> ${OutDir}/${1}/lut.txt
#     count=1
#     for file in ${file_list}; do
#         mask="${Path}/${1}/masks/${file}"
#         cp $mask "${TempDir}/tmp.nii.gz"
#         fslmaths "${TempDir}/tmp.nii.gz" -bin "${TempDir}/tmp.nii.gz"
#         fslmaths "${TempDir}/tmp.nii.gz" \
#             -mul ${count} \
#             "${TempDir}/tmp.nii.gz"
#         fslmaths "${TempDir}/${1}_parc.nii.gz" \
#             -add "${TempDir}/tmp.nii.gz" \
#             "${TempDir}/${1}_parc.nii.gz"
#         progress_bar $count ${filecount}
#         echo "${count} ${file%.nii.gz}" >> ${OutDir}/${1}/lut.txt
#         count=$((count+1))
#     done
#     cp "${TempDir}/${1}_parc.nii.gz" "${OutDir}/${1}/parcellation.nii.gz"
# }




get_parcellation() {
    #
    # $1 input file list name || e.g. ${Seed}
    #
    file_list=($(ls "${Path}/${1}/masks"))
    get_file_count "${file_list[*]}"
    cp ${TEMPLATEDIR}/Atlas/Empty.nii.gz "${TempDir}/${1}_parc.nii.gz"
    GetDimInfo ${TEMPLATEDIR}/Atlas/Empty.nii.gz
    temp_dim=$ImgDim
    GetDimInfo "${Path}/${1}/masks/${file_list[0]}"
    if [ "$temp_dim" != "$ImgDim" ]; then
        ${FSLDIR}/bin/flirt \
                -in "${TempDir}/${1}_parc.nii.gz" \
                -ref "${Path}/${1}/masks/${file_list[0]}" \
                -out "${TempDir}/${1}_parc.nii.gz" \
                -applyxfm \
                -usesqform \
                -interp nearestneighbour
    fi
    touch ${OutDir}/${1}/lut.txt
    echo "ID ROI" >> ${OutDir}/${1}/lut.txt
    count=1
    for file in ${file_list[@]}; do
        mask="${Path}/${1}/masks/${file}"
        cp $mask "${TempDir}/tmp.nii.gz"
        fslmaths "${TempDir}/tmp.nii.gz" -bin "${TempDir}/tmp.nii.gz"
        fslmaths "${TempDir}/tmp.nii.gz" \
            -mul ${count} \
            "${TempDir}/tmp.nii.gz"
        fslmaths "${TempDir}/${1}_parc.nii.gz" \
            -add "${TempDir}/tmp.nii.gz" \
            "${TempDir}/${1}_parc.nii.gz"
        progress_bar $count ${filecount}
        echo "${count} ${file%.nii.gz}" >> ${OutDir}/${1}/lut.txt
        count=$((count+1))
    done
    cp "${TempDir}/${1}_parc.nii.gz" "${OutDir}/${1}/parcellation.nii.gz"
}



# ---- 2. get_tract_mask ---- #
get_tract_mask() {
    # $1 seed name
    # $2 target name

    if [[ "${1}" == "${2}" ]]; then
        # seed == target: produce a single binary mask (value 1)
        fslmaths "${TempDir}/${1}_parc.nii.gz" -bin \
            "${OutDir}/TractMask.nii.gz"
    else
        fslmaths "${TempDir}/${2}_parc.nii.gz" -bin \
            "${TempDir}/${2}_parc_bin.nii.gz"

        fslmaths "${TempDir}/${2}_parc_bin.nii.gz" \
            -add 1 \
            "${TempDir}/${2}_parc_bin2.nii.gz"
        
        fslmaths "${TempDir}/${2}_parc_bin2.nii.gz" \
            -mul "${TempDir}/${2}_parc_bin.nii.gz" \
            "${TempDir}/${2}_parc_bin2.nii.gz"
        
        fslmaths "${TempDir}/${1}_parc.nii.gz" -bin \
            "${TempDir}/${1}_parc_bin.nii.gz"
        
        fslmaths "${TempDir}/${1}_parc_bin.nii.gz" \
            -add "${TempDir}/${2}_parc_bin2.nii.gz" \
            "${OutDir}/TractMask.nii.gz"
    fi

}

# ---- 3. create_full_parc ---- #
create_full_parc() {
    #
    # $1 seed name
    # $2 target name
    #
    if [[ "${1}" == "${2}" ]]; then
        cp "${OutDir}/${1}/parcellation.nii.gz" "${OutDir}/parcellation.nii.gz"
    else
        file_list=$(ls "${Path}/${1}/masks")
        get_file_count "${file_list}"
        fslmaths "${OutDir}/${2}/parcellation.nii.gz" \
            -add ${filecount} \
            "${OutDir}/parcellation.nii.gz"

        fslmaths "${OutDir}/parcellation.nii.gz" -mul \
            "${TempDir}/${2}_parc_bin.nii.gz" \
            "${OutDir}/parcellation.nii.gz"
        
        fslmaths "${OutDir}/parcellation.nii.gz" \
            -add "${OutDir}/${1}/parcellation.nii.gz" \
            "${OutDir}/parcellation.nii.gz"
    fi

}

# ---- 4. get_roi2roi_sc ---- #
get_roi2roi_sc() {
    #
    # extract connectome from subset of tractogram
    # 
    # $1 tractogram input file
    if [[ -z ${1} ]]; then
        tck="${TEMPLATEDIR}/Tractograms/dTOR_2m_tractogram.tck"
    else
        tck=${1}
    fi

    if [[ "${Seed}" == "${Target}" ]]; then
        # ---- seed == target: use tckedit inclusion approach ---- #
        # ---- 1. extract tract subset via inclusion mask ---- #
        tckedit -force -quiet \
            "${tck}" \
            -include "${OutDir}/TractMask.nii.gz" \
            "${OutDir}/tracts_subset.tck"
        # ---- 2. extract connectome from subset (parcellation) ---- #
        tck2connectome -force -symmetric -zero_diagonal -scale_invnodevol \
            "${OutDir}/tracts_subset.tck" \
            "${OutDir}/parcellation.nii.gz" \
            "${OutDir}/sc.tsv"
        # ---- 3. extract connectome from subset (atlas) ---- #
        tck2connectome -force -symmetric -zero_diagonal -scale_invnodevol \
            "${OutDir}/tracts_subset.tck" \
            "${Atlas}" \
            "${OutDir}/sc_full.tsv"
    else
        # ---- seed != target: use assignment-based approach ---- #
        # ---- 1. get tract assignments ---- #
        tck2connectome -force -symmetric -zero_diagonal -quiet \
            "${tck}" \
            "${OutDir}/TractMask.nii.gz"  \
            -out_assignments "${TempDir}/assignments.txt" \
            "${TempDir}/tmp.tsv"
        # ---- 2. extract tract subset ---- #
        connectome2tck -force -exclusive -quiet -files single \
            "${tck}" \
            "${TempDir}/assignments.txt" \
            "${OutDir}/tracts_subset.tck" -nodes "1,2"
        # ---- 3. extract connectome from subset ---- #
        tck2connectome -force -symmetric -zero_diagonal -scale_invnodevol \
            "${OutDir}/tracts_subset.tck" \
            "${OutDir}/parcellation.nii.gz"  \
            "${OutDir}/sc.tsv"
    fi
}

# ---- 5. get_full_sc ---- #
get_full_sc() {
    #
    # extract full connectome from full tractogram
    #
    # $1 tractogram input file
    if [[ -z ${1} ]]; then
        # tck="${TEMPLATEDIR}/Tractograms/HCP422_2_million.tck"
        tck="${TEMPLATEDIR}/Tractograms/dTOR_2m_tractogram.tck"
    else
        tck=${1}
    fi
    # ---- 1. get full connectome ---- #
    tck2connectome -force -symmetric -zero_diagonal -quiet -scale_invnodevol \
        "${tck}" \
        "${OutDir}/parcellation.nii.gz"  \
        "${OutDir}/sc_full.tsv"

}	

# ---- 6. get_lut ---- #
get_lut() {
    #
    # get lut file
    #
    # $1 seed name
    # $2 target name
    cp ${OutDir}/${1}/lut.txt ${TempDir}/lut.txt
    if [[ "${1}" != "${2}" ]]; then
        awk FNR!=1 ${OutDir}/${2}/lut.txt >> ${TempDir}/lut.txt
    fi
    cut -d" " -f2- ${TempDir}/lut.txt > ${TempDir}/lut_rois.txt
    awk -F'\t' -v OFS='\t' '
    NR == 1 {print "ID", $0; next}
    {print (NR-1), $0}
    ' ${TempDir}/lut_rois.txt > ${OutDir}/lut.txt
}

# ---- 7. add_lut_sc ---- #
# add_lut_sc() {
#     # add lut to sc files
#     sc_files=$(ls ${OutDir}/sc*.tsv)
#     tail -n +2 "${TempDir}/lut_rois.txt" >> "${TempDir}/rois.txt"
#     for file in ${sc_files}; do
#         paste -d"\t" "${TempDir}/rois.txt" ${file}  > ${file}
#         # cat "${TempDir}/lut_rois.txt" | cat - ${file%.tsv}_lut.tsv > temp && mv temp ${file%.tsv}2_lut.tsv
#     done
# }

add_lut_sc() {
        # add lut to sc files
    tail -n +2 "${TempDir}/lut_rois.txt" >> "${TempDir}/rois.txt"
    sc_files=$(ls ${OutDir}/sc*.tsv)
    atlas_name=$( basename ${Atlas%.nii.gz} )
    for file in ${sc_files}; do
        filename=$( basename ${file%.tsv})
        # when seed == target, sc_full.tsv is built against the Atlas parcellation,
        # so use the Atlas-specific ROI labels instead of the seed LUT
        if [[ "${Seed}" == "${Target}" && "${filename}" == "sc_full" ]]; then
            if [[ -f "${TEMPLATEDIR}/Atlas/${atlas_name}_ROIs.txt" ]]; then
                rois_file="${TEMPLATEDIR}/Atlas/${atlas_name}_ROIs.txt"
            else
                rois_file="/data/${atlas_name}_ROIs.txt"
            fi
        else
            rois_file="${TempDir}/rois.txt"
        fi
        python -c "import numpy; rois = numpy.genfromtxt('${rois_file}', dtype='str'); sc = numpy.genfromtxt('${file}', dtype='float'); out = numpy.concatenate((rois[:,None], sc.astype(str)), axis=1); rois = ['ROIs'] + rois.tolist(); out = numpy.vstack((rois, out)); numpy.savetxt('${OutDir}/${filename}.tsv', out, fmt='%s', delimiter='\t')"
    done
}



# combine_weights() {
#     # create concatenated connectivity matrix for all ROIs
#     #
#     # ${1}: input directory
#     # ${2}: output filename
#     weight_files="${1}/*.tsv"
#     paste ${weight_files} > ${TempDir}/weights.tsv
#     python -c "import sys; print('\n'.join(' '.join(c) for c in zip(*(l.split() for l in sys.stdin.readlines() if l.strip()))))" < ${TempDir}/weights.tsv > ${2}


# }


######################################
#                                    #
#            disconnectome           #
#                                    #
######################################


get_tract_subset() {
    # return reduced tract subset for given lesion mask
    # $1 lesion mask
    # $2 output filename
    # $3 tractogram
    if [[ -z ${2} ]]; then
        out_file="${1%.nii.gz}_subset.tck"
    else
        out_file=${2}
    fi
    if [[ -z ${3} ]]; then
        tck="${TEMPLATEDIR}/Tractograms/dTOR_2m_tractogram.tck"
    else
        tck=${3}
    fi
    tckedit -force \
        ${tck} \
        -include ${1} \
        ${OutDir}/$( basename ${out_file} )
}


get_disonnectome() {
    # return disconnectome based on tract subset
    # and atlas parcellation
    # $1 tract subset
    # $2 atlas parcellation
    if [[ -z ${1} ]]; then
        log_msg "ERROR | no tract subset provided"
    else
        tck="${1}"
    fi
    if [[ -z ${2} ]]; then
        log_msg "ERROR | using default atlas Schaefer et al. (2018)"
        atlas="${TEMPLATEDIR}/Atlas/Schaefer2018.nii.gz"
    else
        atlas=${2}
    fi
    if [[ -z ${3} ]]; then
        log_msg "UPDATE | using default output name sc_full.tsv"
        out_file="sc_full.tsv"
    else
        out_file=${3}
    fi
    tck2connectome -force -symmetric -zero_diagonal -quiet -scale_invnodevol\
        "${tck}" \
        "${atlas}"  \
        "${out_file}"
}


add_lut_disconnectome() {
    # add lut to sc files
    # $1 Atlas name
    # $2 disconnectome file
    # tail -n +1 ${TEMPLATEDIR}/Atlas/${Atlas}.txt >> ${TempDir}/rois.txt
    if [[ -f "${TEMPLATEDIR}/Atlas/${1}_ROIs.txt" ]]; then
        rois_file="${TEMPLATEDIR}/Atlas/${1}_ROIs.txt"
    else
        rois_file="/data/${1}_ROIs.txt"
    fi
    python -c "import numpy; rois = numpy.genfromtxt('${rois_file}', dtype='str'); sc = numpy.genfromtxt('${2}', dtype='float'); out = numpy.concatenate((rois[:,None], sc.astype(str)), axis=1); rois = ['ROIs'] + rois.tolist(); out = numpy.vstack((rois, out)); numpy.savetxt('${2}', out, fmt='%s', delimiter='\t')"

}


