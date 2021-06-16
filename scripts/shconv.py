import numpy as np
import itertools
import multiprocessing
from dipy.reconst.shm import sh_to_sf_matrix, order_from_ncoef

def convert_sh_basis_parallel(args):
    sh = args[0]
    B_in = args[1]
    invB_out = args[2]
    chunk_id = args[3]

    for idx in range(sh.shape[0]):
        if sh[idx].any():
            sf = np.dot(sh[idx], B_in)
            sh[idx] = np.dot(sf, invB_out)

    return chunk_id, sh

def convert_sh_basis(shm_coeff, sphere, mask=None,
                     input_basis='descoteaux07', nbr_processes=None):
    """Converts spherical harmonic coefficients between two bases
    Parameters
    ----------
    shm_coeff : np.ndarray
        Spherical harmonic coefficients
    sphere : Sphere
        The Sphere providing discrete directions for evaluation.
    mask : np.ndarray, optional
        If `mask` is provided, only the data inside the mask will be
        used for computations.
    input_basis : str, optional
        Type of spherical harmonic basis used for `shm_coeff`. Either
        `descoteaux07` or `tournier07`.
        Default: `descoteaux07`
    nbr_processes: int, optional
        The number of subprocesses to use.
        Default: multiprocessing.cpu_count()
    Returns
    -------
    shm_coeff_array : np.ndarray
        Spherical harmonic coefficients in the desired basis.
    """
    output_basis = 'descoteaux07' if input_basis == 'tournier07' else 'tournier07'

    sh_order = order_from_ncoef(shm_coeff.shape[-1])
    B_in, _ = sh_to_sf_matrix(sphere, sh_order, input_basis)
    _, invB_out = sh_to_sf_matrix(sphere, sh_order, output_basis)

    data_shape = shm_coeff.shape
    if mask is None:
        mask = np.sum(shm_coeff, axis=3).astype(bool)

    nbr_processes = multiprocessing.cpu_count() if nbr_processes is None \
        or nbr_processes < 0 else nbr_processes

    # Ravel the first 3 dimensions while keeping the 4th intact, like a list of
    # 1D time series voxels. Then separate it in chunks of len(nbr_processes).
    shm_coeff = shm_coeff[mask].reshape(
        (np.count_nonzero(mask), data_shape[3]))
    shm_coeff_chunks = np.array_split(shm_coeff, nbr_processes)
    chunk_len = np.cumsum([0] + [len(c) for c in shm_coeff_chunks])

    pool = multiprocessing.Pool(nbr_processes)
    results = pool.map(convert_sh_basis_parallel,
                       zip(shm_coeff_chunks,
                           itertools.repeat(B_in),
                           itertools.repeat(invB_out),
                           np.arange(len(shm_coeff_chunks))))
    pool.close()
    pool.join()

    # Re-assemble the chunk together in the original shape.
    shm_coeff_array = np.zeros(data_shape)
    tmp_shm_coeff_array = np.zeros((np.count_nonzero(mask), data_shape[3]))
    for i, new_shm_coeff in results:
        tmp_shm_coeff_array[chunk_len[i]:chunk_len[i+1], :] = new_shm_coeff

    shm_coeff_array[mask] = tmp_shm_coeff_array

    return shm_coeff_array





