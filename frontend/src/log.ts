export function log(format: string, ...args: any[]): void {
	console.log(format, ...args);
	for (const arg of args) {
		format = format.replace("%O", JSON.stringify(arg, null, 2));
	}
	process.stdout.write(`[${new Date().toISOString()}] ${format}\n`);
}

export function error(format: string, ...args: any[]): void {
	console.error(format, ...args);
	for (const arg of args) {
		const err = arg?.error ? arg.error : arg;
		format = format.replace("%O", `${err} at ${arg?.filename}:${arg?.lineno}`);
	}
	process.stderr.write(`[${new Date().toISOString()}] ${format}\n`);
}
