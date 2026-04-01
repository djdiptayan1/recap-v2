import { performance } from 'perf_hooks';

// Mock dependencies
const SUBCOLLECTIONS = ['immediateQuestions', 'recentQuestions', 'remoteQuestions'];

// Simulated Firebase operations with latency
const mockGetDoc = async () => {
  await new Promise(r => setTimeout(r, 10)); // 10ms network latency
  return { exists: () => true };
};

const mockGetDocs = async (subCol) => {
  await new Promise(r => setTimeout(r, 20)); // 20ms network latency per subcollection query
  return {
    docs: [
      { id: '1', data: () => ({ text: `q1 in ${subCol}` }) },
      { id: '2', data: () => ({ text: `q2 in ${subCol}` }) }
    ]
  };
};

// --- Original Implementation ---
async function fetchQuestionsForDateSequential() {
    const dailyDocSnap = await mockGetDoc();
    if (!dailyDocSnap.exists()) return [];

    const questions = [];
    for (const subCol of SUBCOLLECTIONS) {
        const snapshot = await mockGetDocs(subCol);
        snapshot.docs.forEach(d => {
            questions.push({ id: d.id, ...d.data() });
        });
    }
    return questions;
}

// --- Optimized Implementation ---
async function fetchQuestionsForDateConcurrent() {
    const dailyDocSnap = await mockGetDoc();
    if (!dailyDocSnap.exists()) return [];

    const promises = SUBCOLLECTIONS.map(async (subCol) => {
        const snapshot = await mockGetDocs(subCol);
        return snapshot.docs.map(d => ({ id: d.id, ...d.data() }));
    });

    const results = await Promise.all(promises);
    return results.flat();
}

async function runBenchmark() {
    console.log("Running Sequential Benchmark (simulating 30 days of queries)...");
    let start = performance.now();
    for(let i=0; i<30; i++) {
        await fetchQuestionsForDateSequential();
    }
    let end = performance.now();
    const seqTime = end - start;
    console.log(`Sequential Time: ${seqTime.toFixed(2)}ms\n`);

    console.log("Running Concurrent Benchmark (simulating 30 days of queries)...");
    start = performance.now();
    for(let i=0; i<30; i++) {
        await fetchQuestionsForDateConcurrent();
    }
    end = performance.now();
    const conTime = end - start;
    console.log(`Concurrent Time: ${conTime.toFixed(2)}ms\n`);

    const speedup = ((seqTime - conTime) / seqTime * 100).toFixed(2);
    console.log(`Speedup: ${speedup}%\n`);
}

runBenchmark();
