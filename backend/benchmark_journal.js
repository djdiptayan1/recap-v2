import { performance } from 'perf_hooks';

const simulateUpload = async (i) => {
    return new Promise(resolve => setTimeout(() => resolve({ secure_url: `url_${i}`, public_id: `id_${i}` }), 200));
};

async function sequentialUploads(numPhotos) {
    const photos = [];
    for (let i = 0; i < numPhotos; i++) {
        const uploadResult = await simulateUpload(i);
        if (uploadResult) {
            photos.push({
                url: uploadResult.secure_url || uploadResult.url,
                publicId: uploadResult.public_id,
            });
        }
    }
    return photos;
}

async function concurrentUploads(numPhotos) {
    const uploadPromises = Array.from({ length: numPhotos }).map(async (_, i) => {
        const uploadResult = await simulateUpload(i);
        if (uploadResult) {
            return {
                url: uploadResult.secure_url || uploadResult.url,
                publicId: uploadResult.public_id,
            };
        }
        return null;
    });

    const results = await Promise.all(uploadPromises);
    return results.filter(Boolean);
}

async function run() {
    const numPhotos = 5;

    console.log(`Running benchmark with ${numPhotos} photos...\n`);

    const startSeq = performance.now();
    await sequentialUploads(numPhotos);
    const endSeq = performance.now();
    console.log(`Sequential Uploads: ${(endSeq - startSeq).toFixed(2)} ms`);

    const startCon = performance.now();
    await concurrentUploads(numPhotos);
    const endCon = performance.now();
    console.log(`Concurrent Uploads: ${(endCon - startCon).toFixed(2)} ms`);

    const improvement = ((endSeq - startSeq) / (endCon - startCon)).toFixed(2);
    console.log(`\nConcurrent is ${improvement}x faster!`);
}

run();
