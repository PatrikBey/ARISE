#!/bin/bash
#
#
# # run.sh
#
#
# | ARISE | Automated Regions of Interest Streamline Extraction | 
# | Version | 0.5 |
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
#  This script performs the ARISE pipeline.
#
#


############

# ---- loading I/O & logging functionality ---- #
source ${SRCDIR}/utils.sh
source ${SRCDIR}/functions.sh

figlet "| ARISE |" | lolcat 

log_msg "START | ARISE pipeline |"

# ---- parse input variables ---- #

if [[ ! -d "/data" ]]; then
    log_msg "ERROR | no <</data>> directory mounted into container."
    show_usage
else
    Path="/data"
fi

if [[ -z ${OutDir} ]]; then
    log_msg "UPDATE | using default output directory /arise"
    OutDir="/data/arise"
fi

if [[ ! -d ${OutDir} ]]; then
    mkdir -p ${OutDir}
fi

if [[ -z ${Seed} ]]; then
    log_msg "ERROR | no <<seed>> variable defined."
    show_usage
elif [[ -f "${Path}/${Seed}" ]];then
    log_msg "UPDATE | using ${Seed} as single seed region"
    singleseed="TRUE"
    if [[ -z ${Atlas} ]]; then
        log_msg "UPDATE | using default atlas AAL3"
        Atlas="AAL3v1"
    else
        log_msg "UPDATE | using ${Atlas} as atlas"
    fi
elif [[ -d "${Path}/${Seed}" ]]; then
    log_msg "UPDATE | using ${Seed} as seed regions directory"
    roi2roi="TRUE"
    if [[ -z ${Target} ]]; then
        log_msg "UPDATE | Using ${Seed} as target regions"
        Target=${Seed}
    else
        log_msg "UPDATE | using ${Target} as target regions"
    fi
elif [[ $(contains_string "${Seed}" ",") = "TRUE" ]]; then
    log_msg "UPDATE | using ${Seed} as seed regions list"
    roi2roi="TRUE"
    roilist="TRUE"
    if [[ -z ${Atlas} ]]; then
        log_msg "UPDATE | using default atlas AAL3"
        Atlas="AAL3v1"
    else
        log_msg "UPDATE | using ${Atlas} as atlas"
    fi
    if [[ -z ${Target} ]]; then
        log_msg "UPDATE | Using ${Seed} as target regions"
        Target=${Seed}
    fi
else
    log_msg "ERROR | <<seed>> is not a valid file."
    show_usage
fi

if [[ $(contains_string "${Target}" ",") = "TRUE" ]]; then
    log_msg "UPDATE | using ${Target} as seed regions list"
    roi2roi="TRUE"
    roilist="TRUE"
fi

if [[ ${singleseed} = "TRUE" ]] || [[ ${roilist} = "TRUE" ]] || [[ ${roi2roi} = "TRUE" ]]; then
    AtlasPaths=()
    AtlasNames=()
    IFS=',' read -ra _atlas_entries <<< "${Atlas}"
    for _atlas_entry in "${_atlas_entries[@]}"; do
        _atlas_entry=$(echo "${_atlas_entry}" | tr -d ' ')
        if [[ -f "${TEMPLATEDIR}/Atlas/${_atlas_entry}.nii.gz" ]]; then
            AtlasPaths+=("${TEMPLATEDIR}/Atlas/${_atlas_entry}.nii.gz")
            AtlasNames+=("${_atlas_entry}")
        elif [[ -f "/data/${_atlas_entry}.nii.gz" ]]; then
            log_msg "UPDATE | atlas ${_atlas_entry} not found in template directory, using /data/${_atlas_entry}.nii.gz"
            AtlasPaths+=("/data/${_atlas_entry}.nii.gz")
            AtlasNames+=("${_atlas_entry}")
        else
            log_msg "WARNING | atlas ${_atlas_entry} not found in template directory or /data, skipping."
        fi
    done
    if [[ ${#AtlasPaths[@]} -eq 0 ]]; then
        log_msg "ERROR | no valid atlases found."
        show_usage
    fi
    Atlas="${AtlasPaths[0]}"
fi

if [[ ! -z ${Tracts} ]]; then
    log_msg "UPDATE | using custom tractogram ${Tracts}"
    if [[ ! -f "${Path}/${Tracts}" ]]; then
        log_msg "ERROR | custom tractogram ${Tracts} not found in /data directory."
        show_usage
    else
        Tracts="${Path}/${Tracts}"
    fi
else
    log_msg "UPDATE | using default tractogram"
    # Tracts="${TEMPLATEDIR}/Tractograms/HCP422_2_million.tck"
    Tracts="${TEMPLATEDIR}/Tractograms/dTOR_2m_tractogram.tck"

fi

if [[ -z ${tck_keep} ]]; then
    tck_keep="True"
elif [[ ${tck_keep} != "True" ]]; then
    log_msg "UPDATE | <<tck_keep>> set to False, deleting tract output."
fi


###########################
#           WIP           #
###########################

# ---- preprocessing ---- #

# if [[ ${roilist} = "TRUE" ]]; then
#     log_msg "UPDATE | preparing ROI masks based on ${Seed} list"

#     # ---- prepare ROI mask images ---- #

#     # continue with standard roi2roi below

    
#     #
# fi

# ---- perform computations ---- #

###########################
#           WIP           #
###########################

if [[ ${singleseed} = "TRUE" ]]; then

    # ---- validate input ---- #

    SeedName=$( basename ${Seed})
    log_msg "START | creating disconnectome for ${SeedName}"

    mask="${Path}/${Seed}"

    # ---- extract tract subset once ---- #
    get_temp_dir ${OutDir}

    get_tract_subset ${mask} "${mask%.nii.gz}_subset.tck" ${Tracts}

    # ---- extract disconnectome for each atlas ---- #
    for _i in "${!AtlasPaths[@]}"; do
        _atlas_path="${AtlasPaths[$_i]}"
        _atlas_name="${AtlasNames[$_i]}"
        disc_file=${OutDir}/${SeedName%.nii.gz}_${_atlas_name}.tsv
        log_msg "UPDATE | extracting disconnectome with atlas ${_atlas_name}"
        get_disonnectome ${OutDir}/$( basename ${mask%.nii.gz} )_subset.tck ${_atlas_path} ${disc_file}
        add_lut_disconnectome ${_atlas_name} ${disc_file}
    done

    log_msg "FINISHED | creating disconnectome for ${SeedName}"

    # ---- clean up ---- #
    if [[ -z ${NOCLEANUP} ]]; then
        rm -rf ${TempDir}
    fi

    if [[ ${tck_keep} != "True" ]]; then
        rm -f ${OutDir}/$( basename ${mask%.nii.gz} )_subset.tck
    fi

fi

if [[ ${roi2roi} = "TRUE" ]]; then

    log_msg "START | creating ROI2ROI connectome for ${Seed} and ${Target}"


    # ---- validate input ---- #

    if [[ ! -d "${Path}/${Seed}/masks" ]]; then
        log_msg "ERROR | ${Seed} directory not following input requirements."
        show_usage
    fi
    if [[ ! -d "${Path}/${Target}/masks" ]]; then
        log_msg "ERROR | ${Target} directory not following input requirements."
        show_usage
    fi

    # ---- prepare ROI sets ---- #

    if [[ ! -d ${OutDir}/${Seed} ]]; then
        mkdir -p ${OutDir}/${Seed}
    fi
    if [[ ! -d ${OutDir}/${Target} ]]; then
        mkdir -p ${OutDir}/${Target}
    fi
    # ---- prepare parcellations ---- #

    get_temp_dir ${OutDir}
    log_msg "UPDATE | preparing parcellations for ${Seed}"
    get_parcellation ${Seed}
    if [[ "${Target}" != "${Seed}" ]]; then
        log_msg "UPDATE | preparing parcellations for ${Target}"
        get_parcellation ${Target}
    else
        log_msg "UPDATE | Target is the same as Seed, skipping duplicate parcellation"
    fi
    log_msg "UPDATE | preparing tract mask"
    get_tract_mask ${Seed} ${Target}
    log_msg "UPDATE | creating full parcellation"
    create_full_parc ${Seed} ${Target}

    # ---- prepare connectomes ---- #

    log_msg "UPDATE | extracting subset connectome"
    get_roi2roi_sc ${Tracts}
    log_msg "UPDATE | extracting full connectome"
    if [[ "${Seed}" != "${Target}" ]]; then
        get_full_sc ${Tracts}
    fi
    get_lut ${Seed} ${Target}
    add_lut_sc

    log_msg "FINISHED | creating ROI2ROI connectome for ${Seed} and ${Target}"

    # ---- clean up ---- #
    if [[ -z ${NOCLEANUP} ]]; then
        rm -rf ${TempDir}
    fi
fi

log_msg "FINISHED | ARISE pipeline |"