import { writable, Writable } from "svelte/store";

export interface ErrorMessage {
	msg: string;
	err: null | string | Error | ErrorEvent;
}

export const error: Writable<null | ErrorMessage> = writable(null);
