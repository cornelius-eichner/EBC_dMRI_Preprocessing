import numpy as np

from multiprocessing import cpu_count, Pool

from dipy.core.geometry import cart2sphere
from dipy.core.ndindex import ndindex

from dipy.reconst.shm import sph_harm_lookup
from dipy.reconst.csdeconv import forward_sdt_deconv_mat, odf_deconv


def odf_sh_to_sharp_parallel(odfs_sh, sphere, mask=None, basis=None, ratio=3 / 15., sh_order=8,
                    lambda_=1., tau=0.1, r2_term=False, maxprocess=1):
    r""" Sharpen odfs using the sharpening deconvolution transform [2]_

    This function can be used to sharpen any smooth ODF spherical function. In
    theory, this should only be used to sharpen QballModel ODFs, but in
    practice, one can play with the deconvolution ratio and sharpen almost any
    ODF-like spherical function. The constrained-regularization is stable and
    will not only sharpen the ODF peaks but also regularize the noisy peaks.

    Parameters
    ----------
    odfs_sh : ndarray (``(sh_order + 1)*(sh_order + 2)/2``, )
        array of odfs expressed as spherical harmonics coefficients
    sphere : Sphere
        sphere used to build the regularization matrix
    basis : {None, 'tournier07', 'descoteaux07'}
        different spherical harmonic basis:
        ``None`` for the default DIPY basis,
        ``tournier07`` for the Tournier 2007 [4]_ basis, and
        ``descoteaux07`` for the Descoteaux 2007 [3]_ basis
        (``None`` defaults to ``descoteaux07``).
    ratio : float,
        ratio of the smallest vs the largest eigenvalue of the single prolate
        tensor response function (:math:`\frac{\lambda_2}{\lambda_1}`)
    sh_order : int
        maximal SH order of the SH representation
    lambda_ : float
        lambda parameter (see odfdeconv) (default 1.0)
    tau : float
        tau parameter in the L matrix construction (see odfdeconv)
        (default 0.1)
    r2_term : bool
         True if ODF is computed from model that uses the $r^2$ term in the
         integral.  Recall that Tuch's ODF (used in Q-ball Imaging [1]_) and
         the true normalized ODF definition differ from a $r^2$ term in the ODF
         integral. The original Sharpening Deconvolution Transform (SDT)
         technique [2]_ is expecting Tuch's ODF without the $r^2$ (see [3]_ for
         the mathematical details).  Now, this function supports ODF that have
         been computed using the $r^2$ term because the proper analytical
         response function has be derived.  For example, models such as DSI,
         GQI, SHORE, CSA, Tensor, Multi-tensor ODFs, should now be deconvolved
         with the r2_term=True.

    Returns
    -------
    fodf_sh : ndarray
        sharpened odf expressed as spherical harmonics coefficients

    References
    ----------
    .. [1] Tuch, D. MRM 2004. Q-Ball Imaging.
    .. [2] Descoteaux, M., et al. IEEE TMI 2009. Deterministic and
           Probabilistic Tractography Based on Complex Fibre Orientation
           Distributions
    .. [3] Descoteaux, M., Angelino, E., Fitzgibbons, S. and Deriche, R.
           Regularized, Fast, and Robust Analytical Q-ball Imaging.
           Magn. Reson. Med. 2007;58:497-510.
    .. [4] Tournier J.D., Calamante F. and Connelly A. Robust determination
           of the fibre orientation distribution in diffusion MRI:
           Non-negativity constrained super-resolved spherical deconvolution.
           NeuroImage. 2007;35(4):1459-1472.

    """

    nprocess = min(maxprocess, cpu_count())

    if mask is None:
        mask = np.ones(odfs_sh.shape[:3], dtype=np.bool)

    r, theta, phi = cart2sphere(sphere.x, sphere.y, sphere.z)
    real_sym_sh = sph_harm_lookup[basis]

    B_reg, m, n = real_sym_sh(sh_order, theta, phi)
    R, P = forward_sdt_deconv_mat(ratio, n, r2_term=r2_term)

    # scale lambda to account for differences in the number of
    # SH coefficients and number of mapped directions
    lambda_ = lambda_ * R.shape[0] * R[0, 0] / B_reg.shape[0]


    global _odf_deconv # this is a hack to make the local function pickleable
    def _odf_deconv(odf_sh):
        fodf_sh, _ = odf_deconv(odf_sh, R, B_reg,
                                lambda_=lambda_, tau=tau,
                                r2_term=r2_term)
        return fodf_sh

    fodf_sh = np.zeros(odfs_sh.shape)

    # maybe need chucksize
    with Pool(processes=nprocess) as pool:
        fodf_sh[mask] = pool.map(_odf_deconv, odfs_sh[mask])


    return fodf_sh













