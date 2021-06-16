import numpy as np
from fury import actor, window

from dipy.direction.peaks import peak_directions

from scipy.special import erf
from numpy.lib.scimath import sqrt 

from scipy.interpolate import interp1d

## PEAKS

def peak_directions_vol(odfs, sphere, relative_peak_threshold=0.25, min_separation_angle=15, mask=None):
	vol_shape = odfs.shape[:-1]
	if mask is None:
		mask = np.ones(vol_shape, dtype=np.bool)

	peak_dir = np.zeros(vol_shape + (10,3), dtype=np.float)
	peak_val = np.zeros(vol_shape + (10,), dtype=np.float)
	peak_ind = np.zeros(vol_shape + (10,), dtype=np.int)

	for idx in np.ndindex(vol_shape):
		if mask[idx]:
			single_odf = odfs[idx]

			single_peak_dir, single_peak_val, single_peak_ind = peak_directions(single_odf, sphere, relative_peak_threshold, min_separation_angle)

			peak_dir[idx][:single_peak_dir.shape[0]] = single_peak_dir[:peak_dir.shape[-2]]
			peak_val[idx][:single_peak_val.shape[0]] = single_peak_val[:peak_val.shape[-2]]
			peak_ind[idx][:single_peak_ind.shape[0]] = single_peak_ind[:peak_ind.shape[-2]]

	return peak_dir, peak_val, peak_ind


def peak_directions_sh_vol(odfs_sh, mat, sphere, relative_peak_threshold=0.25, min_separation_angle=15, Npeaks=10, mask=None):
	vol_shape = odfs_sh.shape[:-1]
	if mask is None:
		mask = np.ones(vol_shape, dtype=np.bool)

	peak_dir = np.zeros(vol_shape + (Npeaks,3), dtype=np.float)
	peak_val = np.zeros(vol_shape + (Npeaks,), dtype=np.float)
	peak_ind = np.zeros(vol_shape + (Npeaks,), dtype=np.int)

	for idx in np.ndindex(vol_shape):
		if mask[idx]:
			single_odf = mat.dot(odfs_sh[idx])

			single_peak_dir, single_peak_val, single_peak_ind = peak_directions(single_odf, sphere, relative_peak_threshold, min_separation_angle)

			peak_dir[idx][:single_peak_dir.shape[0]] = single_peak_dir[:peak_dir.shape[-2]]
			peak_val[idx][:single_peak_val.shape[0]] = single_peak_val[:peak_val.shape[-1]]
			peak_ind[idx][:single_peak_ind.shape[0]] = single_peak_ind[:peak_ind.shape[-1]]

	return peak_dir, peak_val, peak_ind




## VIZ

def plot_single_sf(sf, sphere):
	ren = window.Scene()
	ren.SetBackground(1, 1, 1)
	affine = np.eye(4)
	opacity=1.0
	sphere_actor = actor.odf_slicer(sf[None,None,None,:], affine, sphere=sphere,  colormap='winter', scale=0.5, opacity=opacity)
	ren.add(sphere_actor)
	window.show(ren)


def plot_sf(sf, sphere):
	# sf has shape (X,Y,Nsphere)
	ren = window.Scene()
	ren.SetBackground(1, 1, 1)
	affine = np.eye(4)
	opacity=1.0
	sphere_actor = actor.odf_slicer(sf[:,:,None,:], affine, sphere=sphere,  colormap='winter', scale=0.5, opacity=opacity)
	ren.add(sphere_actor)
	window.show(ren)


def plot_single_peaks(peaks_dir, peaks_val):
	# peaks_dir has shape (Npeaks, 3)
	ren = window.Scene()
	ren.SetBackground(1, 1, 1)
	affine = np.eye(4)
	opacity=1.0
	linewidth=4
	peak_actor = actor.peak_slicer(peaks_dir[None, None, None, :, :], peaks_val[None, None, None, :], affine=affine, mask=np.ones((1,1,1), dtype=np.bool), opacity=opacity, linewidth=linewidth)
	ren.add(peak_actor)
	window.show(ren)


def plot_peaks(peaks_dir, peaks_val):
	# peaks_dir has shape (X, Y, Npeaks, 3)
	mask = np.ones((peaks_dir.shape[0], peaks_dir.shape[1],1), dtype=np.bool)
	ren = window.Scene()
	ren.SetBackground(1, 1, 1)
	affine = np.eye(4)
	opacity=1.0
	linewidth=4
	peak_actor = actor.peak_slicer(peaks_dir[:, :, None, :, :], peaks_val[:, :, None, :], affine=affine, mask=mask, opacity=opacity, linewidth=linewidth)
	ren.add(peak_actor)
	window.show(ren)


def plot_single_peaks_and_odf(peaks_dir, peaks_val, sf, sphere):
	# peaks_dir has shape (Npeaks, 3)
	mask = np.ones((1,1,1), dtype=np.bool)
	ren = window.Scene()
	ren.SetBackground(1, 1, 1)
	affine = np.eye(4)
	opacity=1.0
	linewidth=4
	peak_actor = actor.peak_slicer(peaks_dir[None, None, None, :, :], peaks_val[None, None, None, :], affine=affine, mask=mask, opacity=opacity, linewidth=linewidth)
	sphere_actor = actor.odf_slicer(sf[None,None,None,:], affine, sphere=sphere,  colormap='winter', scale=0.5, opacity=opacity)
	ren.add(peak_actor)
	ren.add(sphere_actor)
	window.show(ren)


def plot_peaks_and_odf(peaks_dir, peaks_val, sf, sphere):
	mask = np.ones((peaks_dir.shape[0], peaks_dir.shape[1],1), dtype=np.bool)
	ren = window.Scene()
	ren.SetBackground(1, 1, 1)
	affine = np.eye(4)
	opacity=1.0
	linewidth=4
	peak_actor = actor.peak_slicer(peaks_dir[:, :, None, :, :], peaks_val[:, :, None, :], affine=affine, mask=mask, opacity=opacity, linewidth=linewidth)
	sphere_actor = actor.odf_slicer(sf[:,:,None,:], affine, sphere=sphere,  colormap='winter', scale=0.5, opacity=opacity)
	ren.add(peak_actor)
	ren.add(sphere_actor)
	window.show(ren)



## ODF

# dist on sphere
def sphPDF(k, mu, direc):
	# Generate the PDF for a Von-Mises Fisher distribution p=3
	# at locations direc for concentration k and mean orientation mu
	C3 = k / (2*np.pi*(np.exp(k)-np.exp(-k)))
	tmp = np.exp(k*np.dot(direc,mu[:,None])).squeeze()
	return C3*tmp

# antipodally symetric
# If building a multi-peak ODF, 
# you might want un-normed indivual peak
# this will allow to mak-norm them before averaging
# to control reltaive size of the maximas
def sphPDF_sym(k, mu, direc, norm=False):
	d1 = sphPDF(k, mu, direc)
	d2 = sphPDF(k, mu, -direc)
	dd1 = (d1+d2)/2.
	if norm:
		dd1 = dd1/dd1.sum()
	return dd1


## SM

def Dpar_from_param(MD, ratio):
	return (3*MD*ratio) / (ratio+2)

def Dperp_from_param(MD, ratio):
	dpar = Dpar_from_param(MD, ratio)
	return dpar / ratio

def D_Delta_from_param(MD, ratio):
	Dpar = Dpar_from_param(MD, ratio)
	Dperp = Dperp_from_param(MD, ratio)
	return (Dpar-Dperp)/float(Dpar+2*Dperp)

def gfunc(alpha):
	# return sp.sqrt(np.pi/(4*alpha)) * erf(sp.sqrt(alpha))
	tmp = sqrt(np.pi/np.float64(4.*alpha)) * erf(sqrt(alpha))
	return np.where(np.abs(alpha)<1e-16, 1., np.abs(tmp)) # the abs is missing from the paper

# generic signal formula for any B-tensor shape and any D-tensor shape
def sm_signal_generic(b, bd, Di, Dd):
	return np.exp(-b*Di*(1-bd*Dd)) * gfunc(3*b*Di*bd*Dd)

def SM_from_param(b, MD, ratio):
	D_Delta = D_Delta_from_param(MD, ratio)
	return sm_signal_generic(b=b, bd=1, Di=MD, Dd=D_Delta)


## build "dico"
def true_MD_func(meanbval, ratio, minMD, maxMD, N_MD=1000):
	MDs = np.linspace(minMD, maxMD, N_MD)
	SMs = np.array([SM_from_param(meanbval, MD, ratio) for MD in MDs])
	return interp1d(SMs, MDs, bounds_error=False, fill_value=(minMD, maxMD))



