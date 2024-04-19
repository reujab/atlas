const retries = 3;
const timeout = 5_000;

/**
 * Fetches a resource and retries up to 3 times on network failure or server error.
 * Times out after 5 seconds.
*/
export default async function get(...args: Parameters<typeof fetch>): Promise<Response> {
	const start = Date.now();
	let lastErr;

	for (let i = 0; i < 1 + retries; i++) {
		if (Date.now() - start > timeout) break;

		console.log(`Getting ${args[0]}`);
		try {
			// eslint-disable-next-line no-await-in-loop
			const res = await fetch(...args);
			console.log(`Reply at ${(Date.now() - start) / 1000}s`);

			lastErr = new Error(`Status: ${res.status}`);

			if (res.status >= 500) continue;
			if (res.status !== 200) break;

			return res;
		} catch (err) {
			lastErr = err;
			console.error("Fetch error", err);
		}
	}

	throw lastErr;
}
