import { Plugin } from "@opencode-ai/plugin"
import path from "path"
import os from "os"
import fs from "fs"

const running = new Set<string>();

function splitSentences(text: string): string[] {
	// Split on sentence-ending punctuation, colons, numbered lists, or hyphens followed by whitespace
	return text
		.split(/(?<=[.!?:])\s+|(?<=\d\.)\s+|(?<=-)\s+/)
		.map(s => s.trim())
		.filter(s => s.length > 0);
}

export const NotificationPlugin: Plugin = async ({ client, $ }) => {
	return {
		event: async ({ event }) => {
			if (event.type === "session.idle") {
				const sessionID = event.properties.sessionID;

				if (running.has(sessionID)) return;
				running.add(sessionID);

				const session = await client.session.get({ path: { id: sessionID } });

				if (session.data?.parentID) {
					// Ignore subagents
					running.delete(sessionID);
					return;
				}

				const home = os.homedir();
				const teto = path.join(home, ".opencode/plugins/teto.mp3");
				await $`ffplay -v error -nodisp -autoexit ${teto}`;

				const messages = await client.session.messages({ path: { id: event.properties.sessionID } });

				const lastMessage = messages.data?.at(-1);
				if (!lastMessage) {
					running.delete(sessionID);
					return;
				}

				const text = lastMessage.parts.filter(p => p.type === "text").map(p => p.text).join("")
					.replace(/```[\s\S]*?```/g, ''); // No code blocks

				const voice = path.join(home, ".opencode/plugins/en_US-amy-medium.onnx");
				const sentences = splitSentences(text).map((s) => s.replace(/`|\*|_|-|:|"|'|'|'|"|"|…|–|—/g, ''));

				if (sentences.length === 0) {
					running.delete(sessionID);
					return;
				}

				const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "piper-"));

				// Generate a sentence to a temp wav file, returns path when done
				const generate = async (sentence: string, index: number): Promise<string> => {
					const outFile = path.join(tmpDir, `sentence-${index}.wav`)
					await $`echo ${sentence} | piper -m ${voice} -f ${outFile}`.quiet();
					return outFile;
				}

				try {
					// Generate current sentence
					let nextReady = generate(sentences[0], 0);

					for (let i = 0; i < sentences.length; i++) {
						const sentence = sentences[i];
						const wavFile = await nextReady;

						if (i + 1 < sentences.length) {
							// Kick off next sentence generation in the background while current plays
							nextReady = generate(sentences[i + 1], i + 1);
						}

						$`echo ${sentence} | aosd_cat --font="Sans Bold 60" --fore-color=white --back-color=black --position=7 --x-offset=0 --y-offset=-30 --fade-in=100 --fade-full=60000 --fade-out=3000`.quiet().nothrow().then();
						await $`ffplay -v error -nodisp -autoexit ${wavFile}`.quiet();
						await $`killall aosd_cat`.catch(() => { });
					}
				} finally {
					fs.rmSync(tmpDir, { recursive: true, force: true })
					running.delete(sessionID);
				}
			}
		},
	}
}
