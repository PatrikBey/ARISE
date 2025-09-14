# ARISE (Automated Region of Interest Streamline Extraction)



## Documentation
The data sets found in the template directory consist of the following:

### 1. Normative Tractograms
The normative tractogram provided as default data basis for streamline extraction was originally created by Elias et al. (*1*) and converted into <i>.tck</i> file to enable usability of MRtrix3 (*2*). The conversion from <i>.trk</i> to <i>.tck</i> was performed using <b>Trampolino</b> (*3*). Due to the large size of the tractogram (~12GB) it can not be included in this repository. The file can be reproduced following the steps described here or be provided by contacting the author of this study.

### 2. MNI152 brain parcellations
To enable automated disconnectome creation three default brain parcellations are provided
in MNI152 space.

#### 2.1. Schaefer parcellation
Based on the 400 parcellation in MNI space mapped to the 17 Yeo Networks (*4*).

#### 2.2. Automated Anatomical Labeling Atlas (AAL3)
Latest version of the AAL introduced in (*5*) containing a total of 170 ROIs.

## References

(1) Elias, G. J. B.; Germann, J.; Joel, S. E.; Li, N.; Horn, A.; Boutet, A.; Lozano, A. M.(2024). A large normative connectome for exploring the tractographic correlates of focal brain interventions. Sci Data. 2024 Apr 8;11(1):353. doi: 10.1038/s41597-024-03197-0

(2) Tournier, J. D.; Smith, R.; Raffelt, D.; Tabbara, R.; Dhollander, T.; Pietsch, M.; et al.  (2019). MRtrix3: A fast, flexible and open software framework for medical image processing and visualisation. NeuroImage, 202, 116137. https://doi.org/10.1016/j.neuroimage.2019.116137

(3) Matteo Mancini, https://trampolino.readthedocs.io/en/latest/authors.html#development-lead

(4) Schaefer A, Kong R, Gordon EM, Laumann TO, Zuo XN, Holmes AJ, Eickhoff SB, Yeo BTT. Local-Global parcellation of the human cerebral cortex from intrinsic functional connectivity MRI. Cerebral Cortex, 29:3095-3114, 2018

(5) Rolls ET, Huang CC, Lin CP, Feng J, Joliot M (2020). Rolls, Edmund T., Chu-Chung Huang, Ching-Po Lin, Jianfeng Feng, and Marc Joliot. 2020. “Automated Anatomical Labelling Atlas 3.” NeuroImage 206 (116189): 116189.
