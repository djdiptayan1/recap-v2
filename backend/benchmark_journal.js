
const uploadOnCloudinary = async (buffer, folder, photoId) => {
    // Simulate network delay
    await new Promise(resolve => setTimeout(resolve, 500));
    return {
        secure_url: `https://cloudinary.com/${photoId}.jpg`,
        public_id: photoId
    };
};

const deleteFromCloudinary = async (publicId, type) => {
    // Simulate network delay
    await new Promise(resolve => setTimeout(resolve, 500));
    return { result: 'ok' };
};

const simulateSequentialUpload = async (photoBase64s, patientId) => {
    const photos = [];
    const startTime = Date.now();
    if (photoBase64s && Array.isArray(photoBase64s)) {
        for (let i = 0; i < photoBase64s.length; i++) {
            const { imageBase64, caption } = photoBase64s[i];
            if (!imageBase64) continue;
            const base64Data = imageBase64.replace(/^data:image\/\w+;base64,/, '');
            const buffer = Buffer.from(base64Data, 'base64');
            const photoId = `journal_${patientId}_photo_${Date.now()}_${i}`;
            const uploadResult = await uploadOnCloudinary(buffer, 'recap/journal/photos', photoId);
            if (uploadResult) {
                photos.push({
                    url: uploadResult.secure_url || uploadResult.url,
                    publicId: uploadResult.public_id,
                    caption: caption || '',
                });
            }
        }
    }
    const endTime = Date.now();
    return { photos, duration: endTime - startTime };
};

const simulateParallelUpload = async (photoBase64s, patientId) => {
    let photos = [];
    const startTime = Date.now();
    if (photoBase64s && Array.isArray(photoBase64s)) {
        const uploadPromises = photoBase64s.map(async (photo, i) => {
            const { imageBase64, caption } = photo;
            if (!imageBase64) return null;
            const base64Data = imageBase64.replace(/^data:image\/\w+;base64,/, '');
            const buffer = Buffer.from(base64Data, 'base64');
            const photoId = `journal_${patientId}_photo_${Date.now()}_${i}`;
            const uploadResult = await uploadOnCloudinary(buffer, 'recap/journal/photos', photoId);
            if (uploadResult) {
                return {
                    url: uploadResult.secure_url || uploadResult.url,
                    publicId: uploadResult.public_id,
                    caption: caption || '',
                };
            }
            return null;
        });
        const results = await Promise.all(uploadPromises);
        photos = results.filter(p => p !== null);
    }
    const endTime = Date.now();
    return { photos, duration: endTime - startTime };
};

const simulateSequentialDelete = async (photos) => {
    const startTime = Date.now();
    if (photos && Array.isArray(photos)) {
        for (const photo of photos) {
            if (photo.publicId) {
                await deleteFromCloudinary(photo.publicId, 'image');
            }
        }
    }
    const endTime = Date.now();
    return { duration: endTime - startTime };
};

const simulateParallelDelete = async (photos) => {
    const startTime = Date.now();
    const deletionPromises = [];
    if (photos && Array.isArray(photos)) {
        photos.forEach(photo => {
            if (photo.publicId) {
                deletionPromises.push(deleteFromCloudinary(photo.publicId, 'image'));
            }
        });
    }
    if (deletionPromises.length > 0) {
        await Promise.all(deletionPromises);
    }
    const endTime = Date.now();
    return { duration: endTime - startTime };
};

const runBenchmark = async () => {
    const photoBase64s = Array(5).fill({ imageBase64: 'data:image/png;base64,mockdata', caption: 'test' });
    const patientId = 'test_patient';

    console.log('--- Sequential benchmark ---');
    const seqUploadResults = await simulateSequentialUpload(photoBase64s, patientId);
    console.log(`Sequential Upload Duration: ${seqUploadResults.duration}ms`);
    const seqDeleteResults = await simulateSequentialDelete(seqUploadResults.photos);
    console.log(`Sequential Delete Duration: ${seqDeleteResults.duration}ms`);
    const totalSeq = seqUploadResults.duration + seqDeleteResults.duration;
    console.log(`Total Sequential Duration: ${totalSeq}ms`);

    console.log('\n--- Parallel benchmark ---');
    const parUploadResults = await simulateParallelUpload(photoBase64s, patientId);
    console.log(`Parallel Upload Duration: ${parUploadResults.duration}ms`);
    const parDeleteResults = await simulateParallelDelete(parUploadResults.photos);
    console.log(`Parallel Delete Duration: ${parDeleteResults.duration}ms`);
    const totalPar = parUploadResults.duration + parDeleteResults.duration;
    console.log(`Total Parallel Duration: ${totalPar}ms`);

    console.log('\n--- Results ---');
    console.log(`Improvement: ${totalSeq - totalPar}ms (${((totalSeq - totalPar) / totalSeq * 100).toFixed(2)}%)`);
};

runBenchmark();
