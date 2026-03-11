const SUBCOLLECTIONS = ['immediateQuestions', 'recentQuestions', 'remoteQuestions'];

const getDocsMock = async (subColRef) => {
    return new Promise(resolve => setTimeout(() => resolve({
        docs: [
            { id: '1', data: () => ({ q: 'mock data' }) },
            { id: '2', data: () => ({ q: 'mock data 2' }) }
        ]
    }), 50));
}

async function fetchQuestionsSequential() {
    const questions = [];
    for (const subCol of SUBCOLLECTIONS) {
        const snapshot = await getDocsMock(subCol);
        snapshot.docs.forEach(d => {
            questions.push({ id: d.id, ...d.data() });
        });
    }
    return questions;
}

async function fetchQuestionsParallel() {
    const promises = SUBCOLLECTIONS.map(subCol => getDocsMock(subCol));
    const snapshots = await Promise.all(promises);
    const questions = [];
    snapshots.forEach(snapshot => {
        snapshot.docs.forEach(d => {
            questions.push({ id: d.id, ...d.data() });
        });
    });
    return questions;
}

async function runBenchmark() {
    console.log("Running Sequential Fetch...");
    const startSeq = Date.now();
    await fetchQuestionsSequential();
    const endSeq = Date.now();
    console.log(`Sequential took: ${endSeq - startSeq}ms\n`);

    console.log("Running Parallel Fetch...");
    const startPar = Date.now();
    await fetchQuestionsParallel();
    const endPar = Date.now();
    console.log(`Parallel took: ${endPar - startPar}ms\n`);

    const improvement = ((endSeq - startSeq) - (endPar - startPar)) / (endSeq - startSeq) * 100;
    console.log(`Improvement: ${improvement.toFixed(2)}%`);
}

runBenchmark();
