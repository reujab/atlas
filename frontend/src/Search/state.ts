import { Title } from "../db";
import { Writable, writable } from "svelte/store";

export const query = writable("");

export const autocompleteCache: Writable<{ [query: string]: Title[] }> = writable({});
