import numpy as np
import nibabel as nib
from time import time

from dipy.data import get_sphere
from dipy.reconst.shm import real_sh_tournier
from dipy.reconst.shm import calculate_max_order


def main(sh_fname, sh_norm_fname):

    sh_img = nib.load(sh_fname)
    sh = sh_img.get_fdata()
    affine = sh_img.affine

    lmax = calculate_max_order(sh.shape[3], False)

    sphere = get_sphere('repulsion724')
    # sphere = get_sphere('repulsion100')
    B, m, n = real_sh_tournier(lmax, sphere.theta, sphere.phi)


    sf_maximum = np.zeros(sh.shape[:3])

    start_time = time()
    for Z in range(sh.shape[2]):
        print('Processing Z slice {:} / {:}'.format(Z, sh.shape[2]))

        tmp = sh[:,:,Z,:].dot(B.T)
        sf_maximum[:,:,Z] = tmp.max(axis=2)


    sh_maxnorm = sh / sf_maximum[:,:,:,None]
    sh_maxnorm[np.isnan(sh_maxnorm)] = 0
    sh_maxnorm[np.isinf(sh_maxnorm)] = 0

    end_time = time()
    print('Elapsed time (sh normalization) = {:.2f} s'.format(end_time - start_time))

    nib.Nifti1Image(sh_maxnorm, affine).to_filename(sh_norm_fname)


if __name__ == "__main__":
    import sys
    main(*sys.argv[1:])


