import { performance } from 'perf_hooks';

// Mock deleteFromCloudinary
const deleteFromCloudinary = async (publicId, type) => {
    return new Promise(resolve => setTimeout(resolve, 100)); // Simulate 100ms network call
};

const runBenchmark = async () => {
    const entryData = {
        photos: Array.from({ length: 5 }, (_, i) => ({ publicId: `photo_${i}` }))
    };

    console.log("Running sequential deletion...");
    const startSeq = performance.now();
    if (entryData.photos && Array.isArray(entryData.photos)) {
        for (const photo of entryData.photos) {
            if (photo.publicId) {
                await deleteFromCloudinary(photo.publicId, 'image');
            }
        }
    }
    const endSeq = performance.now();
    console.log(`Sequential took: ${endSeq - startSeq}ms`);

    console.log("\nRunning parallel deletion...");
    const startPar = performance.now();
    if (entryData.photos && Array.isArray(entryData.photos)) {
        const deletePromises = entryData.photos
            .filter(photo => photo.publicId)
            .map(photo => deleteFromCloudinary(photo.publicId, 'image'));
        await Promise.all(deletePromises);
    }
    const endPar = performance.now();
    console.log(`Parallel took: ${endPar - startPar}ms`);
};

runBenchmark();
