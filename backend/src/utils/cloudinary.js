import { v2 as cloudinary } from 'cloudinary';
import 'dotenv/config';

cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET
});

const DEFAULT_IMAGE_DELIVERY = {
    fetch_format: 'auto',
    quality: 'auto',
};

const IMAGE_PRESETS = {
    default: {
        ...DEFAULT_IMAGE_DELIVERY,
    },
    avatar: {
        ...DEFAULT_IMAGE_DELIVERY,
        width: 200,
        height: 200,
        crop: 'fill',
        gravity: 'face',
    },
    thumbnail: {
        ...DEFAULT_IMAGE_DELIVERY,
        width: 400,
        height: 400,
        crop: 'thumb',
        gravity: 'auto',
    },
    detail: {
        ...DEFAULT_IMAGE_DELIVERY,
        width: 1200,
        crop: 'limit',
    },
    articleThumbnail: {
        ...DEFAULT_IMAGE_DELIVERY,
        width: 800,
        height: 450,
        crop: 'fill',
        gravity: 'auto',
    },
    articleDetail: {
        ...DEFAULT_IMAGE_DELIVERY,
        width: 1400,
        crop: 'limit',
    },
};

const CLOUDINARY_HOST_PATTERN = /(?:^|\.)cloudinary\.com$/i;

function looksLikeTransformationSegment(segment) {
    if (!segment) return false;

    return [
        'c_',
        'w_',
        'h_',
        'g_',
        'q_',
        'f_',
        'dpr_',
        'fl_',
        'e_',
        'ar_',
        'x_',
        'y_',
        'z_',
        'r_',
        'a_',
        'bo_',
        'b_',
        'o_',
        '$',
    ].some(prefix => segment.startsWith(prefix));
}

/**
 * Uploads a file buffer to Cloudinary
 * @param {Buffer} fileBuffer - Buffer of the file
 * @param {string} [folder="recap"] - Folder in Cloudinary
 * @param {string} [filename] - Original filename (without extension preferred)
 * @returns {Promise<import('cloudinary').UploadApiResponse|null>}
 */
const uploadOnCloudinary = async (fileBuffer, folder = "recap", filename, transformation = []) => {
    try {
        if (!fileBuffer) return null;

        // Sanitize filename if provided
        const publicId = filename
            ? filename.trim().replace(/\s+/g, '_').replace(/[^a-zA-Z0-9_]/g, '')
            : undefined;

        return new Promise((resolve, reject) => {
            const uploadStream = cloudinary.uploader.upload_stream(
                {
                    resource_type: "auto",
                    folder: folder,
                    public_id: publicId,
                    use_filename: true,
                    unique_filename: false,
                    overwrite: true,
                    invalidate: true
                },
                (error, result) => {
                    if (error) {
                        console.error("Error uploading to Cloudinary:", error);
                        reject(null);
                    } else {
                        console.log("File is uploaded on Cloudinary ", result.url);
                        resolve(result);
                    }
                }
            );

            uploadStream.end(fileBuffer);
        });

    } catch (error) {
        console.error("Error in uploadOnCloudinary:", error);
        return null;
    }
}

/**
 * Generates signed upload params for direct client-to-Cloudinary uploads.
 * The client uploads to Cloudinary directly and later sends only the URL/public_id
 * back to the API, which keeps Vercel function payloads small.
 * @param {object} options
 * @param {string} options.folder
 * @param {string} options.publicId
 * @param {string} [options.resourceType="auto"]
 * @param {boolean} [options.overwrite=true]
 * @param {boolean} [options.invalidate=true]
 * @returns {object}
 */
const generateSignedUploadParams = ({
    folder = 'recap',
    publicId,
    resourceType = 'auto',
    overwrite = true,
    invalidate = true,
} = {}) => {
    const timestamp = Math.floor(Date.now() / 1000);
    const paramsToSign = {
        folder,
        public_id: publicId,
        overwrite: overwrite ? 'true' : 'false',
        invalidate: invalidate ? 'true' : 'false',
        timestamp,
    };

    const signature = cloudinary.utils.api_sign_request(
        paramsToSign,
        process.env.CLOUDINARY_API_SECRET
    );

    return {
        cloudName: process.env.CLOUDINARY_CLOUD_NAME,
        apiKey: process.env.CLOUDINARY_API_KEY,
        uploadUrl: `https://api.cloudinary.com/v1_1/${process.env.CLOUDINARY_CLOUD_NAME}/${resourceType}/upload`,
        resourceType,
        folder,
        publicId,
        overwrite,
        invalidate,
        timestamp,
        signature,
    };
};

/**
 * Deletes a file from Cloudinary
 * @param {string} publicId - Public ID of the asset
 * @param {string} [resourceType="image"] - Resource type (image, video, raw)
 * @returns {Promise<import('cloudinary').DeleteApiResponse>}
 */
const deleteFromCloudinary = async (publicId, resourceType = "image") => {
    try {
        if (!publicId) return null;
        const response = await cloudinary.uploader.destroy(publicId, {
            resource_type: resourceType
        });

        return response;
    } catch (error) {
        console.error("Error deleting from Cloudinary:", error);
        return null;
    }
}

/**
 * Generates an optimized URL for a Cloudinary asset
 * @param {string} publicId - Public ID of the asset
 * @param {object} [options={}] - Additional transformation options
 * @returns {string}
 */
const getOptimizedUrl = (publicId, options = {}) => {
    try {
        if (!publicId) return null;

        return cloudinary.url(publicId, {
            ...DEFAULT_IMAGE_DELIVERY,
            ...options
        });
    } catch (error) {
        console.error("Error generating Cloudinary URL:", error);
        return null;
    }
}

function isCloudinaryUrl(url) {
    if (!url || typeof url !== 'string') return false;

    try {
        const parsed = new URL(url);
        return CLOUDINARY_HOST_PATTERN.test(parsed.hostname);
    } catch {
        return false;
    }
}

function extractPublicIdFromUrl(url) {
    if (!isCloudinaryUrl(url)) return null;

    try {
        const parsed = new URL(url);
        const pathSegments = parsed.pathname.split('/').filter(Boolean);
        const uploadIndex = pathSegments.findIndex(segment => segment === 'upload');
        if (uploadIndex === -1 || uploadIndex === pathSegments.length - 1) return null;

        const assetSegments = pathSegments.slice(uploadIndex + 1);
        const versionIndex = assetSegments.findIndex(segment => /^v\d+$/.test(segment));
        let publicIdSegments;
        if (versionIndex >= 0) {
            publicIdSegments = assetSegments.slice(versionIndex + 1);
        } else if (looksLikeTransformationSegment(assetSegments[0])) {
            publicIdSegments = assetSegments.slice(1);
        } else {
            publicIdSegments = assetSegments;
        }

        if (!publicIdSegments.length) return null;

        const normalizedSegments = [...publicIdSegments];
        const lastSegment = normalizedSegments[normalizedSegments.length - 1];
        normalizedSegments[normalizedSegments.length - 1] = lastSegment.replace(/\.[^.]+$/, '');

        return normalizedSegments.join('/');
    } catch (error) {
        console.error("Error extracting Cloudinary public ID:", error);
        return null;
    }
}

function getOptimizedImageUrl(source, preset = 'default', overrides = {}) {
    try {
        if (!source) return null;

        const publicId = isCloudinaryUrl(source) ? extractPublicIdFromUrl(source) : source;
        if (!publicId) return source;

        const presetOptions = IMAGE_PRESETS[preset] || IMAGE_PRESETS.default;
        return getOptimizedUrl(publicId, {
            ...presetOptions,
            ...overrides,
        });
    } catch (error) {
        console.error("Error generating optimized image URL:", error);
        return source;
    }
}

function buildResponsiveImageSet(source, presets = {}) {
    if (!source) return null;

    const originalURL = isCloudinaryUrl(source) ? source : null;

    return {
        originalURL: originalURL || source,
        thumbnailURL: getOptimizedImageUrl(source, presets.thumbnail || 'thumbnail'),
        detailURL: getOptimizedImageUrl(source, presets.detail || 'detail'),
    };
}

export {
    uploadOnCloudinary,
    generateSignedUploadParams,
    deleteFromCloudinary,
    getOptimizedUrl,
    getOptimizedImageUrl,
    buildResponsiveImageSet,
    extractPublicIdFromUrl,
    isCloudinaryUrl,
};
