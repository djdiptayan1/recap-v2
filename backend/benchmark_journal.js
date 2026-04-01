async function uploadOnCloudinaryMock(buffer, folder, id) {
    return new Promise(resolve => setTimeout(() => resolve({ secure_url: 'mock_url', public_id: id }), 200));
}

async function runBenchmark() {
    console.log("Starting benchmark...");
    console.time('Sequential Upload');
    const photoBase64s = Array(5).fill({ imageBase64: 'data:image/png;base64,mock', caption: 'test' });
    const patientId = 'test_patient';

    const photosSeq = [];
    for (let i = 0; i < photoBase64s.length; i++) {
        const { imageBase64, caption } = photoBase64s[i];
        if (!imageBase64) continue;
        const base64Data = imageBase64.replace(/^data:image\/\w+;base64,/, '');
        const buffer = Buffer.from(base64Data, 'base64');
        const photoId = `journal_${patientId}_photo_${Date.now()}_${i}`;
        const uploadResult = await uploadOnCloudinaryMock(buffer, 'recap/journal/photos', photoId);
        if (uploadResult) {
            photosSeq.push({
                url: uploadResult.secure_url || uploadResult.url,
                publicId: uploadResult.public_id,
                caption: caption || '',
            });
        }
    }
    console.timeEnd('Sequential Upload');

    console.time('Concurrent Upload');
    const uploadPromises = photoBase64s.map(async (photo, i) => {
        const { imageBase64, caption } = photo;
        if (!imageBase64) return null;
        const base64Data = imageBase64.replace(/^data:image\/\w+;base64,/, '');
        const buffer = Buffer.from(base64Data, 'base64');
        const photoId = `journal_${patientId}_photo_${Date.now()}_${i}`;
        const uploadResult = await uploadOnCloudinaryMock(buffer, 'recap/journal/photos', photoId);
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
    const photosConc = results.filter(p => p !== null);
    console.timeEnd('Concurrent Upload');
}

runBenchmark();
