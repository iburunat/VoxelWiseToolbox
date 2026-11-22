function [data, metadata] = fmri_readnii(filename)
% FMRI_READNII  Reads a 3D or 4D NIfTI (.nii) or Analyze (.img/.hdr) file.
%
% Reads volumetric brain data and returns both the image array and a
% metadata structure. Works for both 3D (single volume) and 4D (time series)
% files. If no filename is supplied, a file-open dialog is shown.
%
% Usage:
%   [data, metadata] = fmri_readnii()
%   [data, metadata] = fmri_readnii('subject01.nii')
%   [data, metadata] = fmri_readnii('/path/to/data.img')
%
% Inputs:
%   FILENAME  - Path to a .nii or .img file (string). Optional: if omitted,
%               a file-open dialog is displayed.
%
% Outputs:
%   DATA      - Image array, [X Y Z] for 3D or [X Y Z T] for 4D data.
%               Always returned as double to support subsequent numerical
%               processing without integer rounding or saturation. The
%               original storage class is reported in METADATA.origclass.
% 
%   METADATA  - Structure with fields:
%                 .hdr        - Full NIfTI/Analyze header
%                 .filetype   - File type code
%                 .fileprefix - Filename without extension
%                 .machine    - Byte-order string
%                 .original   - Original header struct
%                 .origclass  - Class of the image data as stored on disk
%
% Examples:
%   [vol, meta] = fmri_readnii('anat.nii');
%   [ts,  meta] = fmri_readnii('bold_run1.nii');
%   [vol, meta] = fmri_readnii();   % opens file dialog
%
% Notes:
%   This function handles both 3D and 4D files, replacing the former
%   fmri_read3Dnii and fmri_read4Dnii functions.
%
%   Files are read with load_nii, which applies the available sform/qform
%   orientation information. Use load_untouch_nii instead if the image array
%   and header must remain exactly as stored.
%
%   fmri_export creates a new header from the voxel size and origin rather
%   than preserving the complete header read here. A read-modify-write cycle
%   therefore preserves the image data and basic geometry, but may not retain
%   other header information.
% 
% See also: fmri_export, fmri_vol2vect, fmri_vect2vol

if nargin < 1 || isempty(filename)
    [fname, fpath] = uigetfile({'*.nii;*.img', 'NIfTI and Analyze files (*.nii, *.img)'}, ...
                                'Select a NIfTI or Analyze file');
    if isequal(fname, 0)
        error('fmri_readnii:noFileSelected', 'No file selected.');
    end
    filename = fullfile(fpath, fname);
end

% Ensure .nii extension is appended when base name given without extension
[~, ~, ext] = fileparts(filename);
if isempty(ext)
    filename = [filename '.nii'];
end

if ~isfile(filename)
    % Analyze pairs are named .img/.hdr, so a missing .nii may just mean the
    % caller has the other form.
    [p, n, ~] = fileparts(filename);
    alt = fullfile(p, [n '.img']);
    if isfile(alt)
        filename = alt;
    else
        error('fmri_readnii:fileNotFound', ...
              ['Cannot find ''%s''.\n' ...
               'Give a full path, or omit the argument to browse for a file.'], ...
              filename);
    end
end

img = load_nii(filename);

% Convert the image data to double for reliable numerical processing. NIfTI
% files are often stored as integers, which can cause rounding or saturation
% during operations such as detrending, standardisation and filtering.
% load_nii has already applied any intensity scaling specified in the header.
data                = double(img.img);
metadata.hdr        = img.hdr;
metadata.filetype   = img.filetype;
metadata.fileprefix = img.fileprefix;
metadata.machine    = img.machine;
metadata.original   = img.original;
metadata.origclass  = class(img.img);   % the on-disk class, before casting

% Warn when the image does not use the toolbox's 91 x 109 x 91 MNI152 2 mm
% grid. Other grids can still be read but must be resampled with fmri_tomni152
% before vectorisation with fmri_vol2vect.
sz = size(data);
if ~isequal(sz(1:3), [91 109 91])
    warning('fmri_readnii:nonStandardGrid', ...
            ['''%s'' is %dx%dx%d, not the 91x109x91 MNI152 2mm grid.\n' ...
             'Use fmri_tomni152 to resample it before fmri_vol2vect.'], ...
            filename, sz(1), sz(2), sz(3));
end