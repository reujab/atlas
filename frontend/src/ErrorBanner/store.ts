import { writable, Writable } from "svelte/store";

export interface ErrorMessage {
	msg: string;
	err: any;
}

export const error: Writable<null | ErrorMessage> = writable(null);
