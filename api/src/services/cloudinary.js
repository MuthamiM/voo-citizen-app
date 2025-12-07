// Cloudinary Service - Image Upload & Optimization
const cloudinary = require('cloudinary').v2;

// Configure Cloudinary
cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET
});

// Upload image from base64 or URL
async function uploadImage(imageData, options = {}) {
    try {
        const uploadOptions = {
            folder: 'voo-citizen/issues',
            resource_type: 'image',
            transformation: [
                { width: 1200, height: 1200, crop: 'limit' }, // Max dimensions
                { quality: 'auto:good' },
                { fetch_format: 'auto' }
            ],
            ...options
        };

        // Handle base64 or URL
        const dataUri = imageData.startsWith('data:')
            ? imageData
            : imageData.startsWith('http')
                ? imageData
                : `data:image/jpeg;base64,${imageData}`;

        const result = await cloudinary.uploader.upload(dataUri, uploadOptions);

        return {
            url: result.secure_url,
            publicId: result.public_id,
            width: result.width,
            height: result.height,
            format: result.format,
            bytes: result.bytes
        };
    } catch (error) {
        console.error('Cloudinary upload error:', error.message);
        throw new Error('Image upload failed');
    }
}

// Upload multiple images
async function uploadMultipleImages(images, maxImages = 5) {
    const uploads = images.slice(0, maxImages).map((img, index) =>
        uploadImage(img, { public_id: `issue_${Date.now()}_${index}` })
    );

    return Promise.all(uploads);
}

// Delete image
async function deleteImage(publicId) {
    try {
        await cloudinary.uploader.destroy(publicId);
        return true;
    } catch (error) {
        console.error('Cloudinary delete error:', error.message);
        return false;
    }
}

// Get optimized URL
function getOptimizedUrl(publicId, options = {}) {
    return cloudinary.url(publicId, {
        fetch_format: 'auto',
        quality: 'auto',
        ...options
    });
}

// Get thumbnail URL
function getThumbnailUrl(publicId, size = 200) {
    return cloudinary.url(publicId, {
        width: size,
        height: size,
        crop: 'fill',
        gravity: 'auto',
        fetch_format: 'auto',
        quality: 'auto'
    });
}

module.exports = {
    uploadImage,
    uploadMultipleImages,
    deleteImage,
    getOptimizedUrl,
    getThumbnailUrl
};
