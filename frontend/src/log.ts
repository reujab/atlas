export function log(format: string, ...args: any[]) {
	console.log(format, ...args);
	for (const arg of args) {
		format = format.replace("%O", JSON.stringify(arg, null, 2));
	}
	process.stdout.write(`${format}\n`);
}

export function error(format: string, ...args: any[]) {
	console.error(format, ...args);
	for (const arg of args) {
		let error = arg;
		if (arg?.error) {
			error = arg.error
		}
		format = format.replace("%O", `${error} at ${arg?.filename}:${arg?.lineno}`);
	}
	process.stderr.write(`${format}\n`);
}
