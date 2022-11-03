import { error as errorStore } from "./ErrorBanner/store";

export function log(format: string, ...args: any[]): void {
	console.log(format, ...args);
	for (const arg of args) {
		format = format.replace("%O", JSON.stringify(arg, null, 2));
	}
	process.stdout.write(`[${new Date().toISOString()}] ${format}\n`);
}

export function error(msg: string, err?: any): void {
	console.error(msg, err);
	process.stderr.write(`[${new Date().toISOString()}] ${msg}${err ? `: ${err}` : ""}\n`);
	errorStore.update(() => ({ msg, err }));
}
