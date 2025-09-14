<!-- <p align='center'>
    <img src= 'images/banner.png'>
</p> -->

<p align="left">
    <!-- <a href="https://zenodo.org/badge/latestdoi/523258545"><img src="https://zenodo.org/badge/523258545.svg" alt="DOI"></a> -->
    <a href="https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12" alt="License-EUPL-1.2-or-later">
        <img src="https://img.shields.io/badge/license-EUPL--1.2--or--later-green" /></a>
</p>

# *A*utomated *R*egion of *I*nterest *S*treamline *E*xtraction (ARISE): 
a containerized readily delpoyable framework for automated ROI based tractography. The framework provides two main functionalities:

## ABOUT

This code has been developed by the 
Author: \
Patrik Bey, <a href="https://github.com/PatrikBey" target="_blank">Patrik Bey</a>


## ROI2ROI connectivity
To extract structural connectivity estimates between sets of ROIs this module extracts tractography strength estimates connecting both disjunct sets of ROIs in two ways:
1. only return white matter tracts that start/end in any of the provided ROIs.
2. provide white matter tracts estimates based on the full normative tractogram between any pair of ROIs.

## DISCONNECTOME extraction
To automaticcaly create disconnectomes from a provided ROI mask, e.g. a lesion mask, the framework computes the corresponding disconnecte using one of the integrated MNI152 space registered brain parcellations (see Templates)


## USAGE

The corresponding docker container can be accessed on <a href="https://hub.docker.com/r/patrikneuro/arise">dockerhub</a>


```bash
docker pull patrikneuro/arise:0.1
```

### USAGE - ROI2ROI

To extract streamlines between two defined sets of ROIs the following steps need to be performed:

1. prepare ROI volume masks
2. run *arise* container with corresponding input variables.

Arise expects the following structure of ROI volume masks for automated extraction
```
STUDYFOLDER
    |_SEEDNAME
        |_masks
            |_ROI1.nii.gz
            |_ ...
    |_TARGETNAME
        |_masks
            |_ROI1.nii.gz
            |_ ...
```

The corresponding container call for the given example is given by:

```
    docker run \
        -v STUDYFOLDER:/data \
        -e Seed=SEEDNAME \
        -e Target=TARGETNAME \
        -e OutDir=ROI2ROIEXAMPLE \
        patrikneuro/arise:0.1

```

The output will be created within the defined output directory STUDYFOLDER/ROI2ROIEXAMPLE and contains the following list of files:

```
SEEDNAME/parcellation.nii.gz    | parcellation volume containing all SEED ROIs
SEEDNAME/lut.txt                | look-up table of SEED ROI parcellation volume
TARGETNAME/parcellation.nii.gz  | parcellation volume containing all TARGET ROIs
TARGETNAME/lut.txt              | look-up table of TARGET ROI parcellation volume
parcellation.nii.gz             | parcellation file for all SEED and TARGET ROIs
lut.txt                         | look-up table for combined parcellation
TractMask.nii.gz                | Mask volume used to extract streamlines starting in SEED and ending in TARGET ROIs
tracts_subset.tck               | subset of streamlines starting and ending in SEED and TARGET ROIs respectively
temp-xyz                        | directory containing interim files used during ARISE pipeline run
sc.tsv                          | structural connectome file containing streamlines ending and starting in SEED and TARGET ROIs respectively
sc_full.tsv                     | structural connectome file containing all streamlines intersecting with SEED and TARGET ROIs

```

### USAGE - DISCONNECTOME

To extract the disconnectome based on a single ROI, e.g. lesion mask, the ARISE

1. run *arise* container with corresponding input variables.

Arise expects the following structure of ROI volume masks for automated extraction

```
STUDYFOLDER
    |_ (...)                    | optional folder structure within STUDYFOLDER. Has to be part of provided filename for SEED variable.
        |_ROIMASK.nii.gz
```

The corresponding container call for the given example is given by:

```
    docker run \
        -v STUDYFOLDER:/data \
        -e Seed=(...)/ROIMASK.nii.gz \
        -e Atlas=AAL3v1 \
        -e OutDir=DISCONNECTOMEEXAMPLE \
        patrikneuro/arise:0.1

```
The atlas variable defines the used atlas parcellation for creating the disconnectome. ALL3v1 (*3.*) is used as default. Currently also available is "Schaefer2018" (*4.*). Future releases may contain further parcellations.


The output will be created within the defined output directory STUDYFOLDER/CONNECTOMEEXAMPLE and contains the following list of files:

```
ROIMASK_AAL3v1.tsv          | disconnectome file
ROIMASK_subset.tck          | subset of streamlines intersecting the provided ROI mask
temp-xyz                    | directory containing interim files used during ARISE pipeline run
```



### TEMPLATES

Currently integrated *atlas* parcellations include:

1. AAL3v1, 
2. Schaefer2018, 

The baseline tractogram used in this framework has been adjusted from *1* by converting it into a MRTrix3 *2* compatible .tck file format.


## REFERNCES

1. Elias et al., A large normative connectome for exploring the tractographic correlates of focal brain interventions, 2024, *Scientific Data*, DOI:10.1038/s41597-024-03197-0
2. Tournier et al., MRtrix3: A fast, flexible and open software framework for medical image processing and visualisation, 2019, *NeuroImage* , DOI:10.1016/j.neuroimage.2019.11613
3. Rolls et al., Automated anatomical labelling atlas 3, 2020, *NeuroImage*, DOI:10.1016/j.neuroimage.2019.116189
4. Schaefer et al., Local-Global Parcellation of the Human Cerebral Cortex from Intrinsic Functional Connectivity MRI. 2017, *Cerebral Cortex*, DOI:10.1093/cercor/bhx179
