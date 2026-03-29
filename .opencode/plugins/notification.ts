import { Plugin } from "@opencode-ai/plugin"
import path from "path"
import os from "os"

const running = new Set<string>();

function splitSentences(text: string): string[] {
	const sections = text.split(/(?=^#{1,6}\s)|(?<=^[*]{2}[^*]+[*]{2}:$)|(?<=\d\.)\s+(?=- )|(?=^- )|(?=^\* )|\n\n+/m);
	const sentences: string[] = [];
	for (const section of sections) {
		const lines = section.split(/(?<=[.!?:](?![^"]*"))\s+/);
		for (const line of lines) {
			const trimmed = line.trim();
			const isOnlyHeader = /^(#{1,6}\s|[*]{2}[^*]+[*]{2}:)$/.test(trimmed);
			if (trimmed.length > 3 && !/^[-| ]+$/.test(trimmed) && !isOnlyHeader) {
				sentences.push(trimmed);
			}
		}
	}
	return sentences;
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
				const sentences = splitSentences(text).map((s) => s.replace(/`|\*|_|-|:|"|'|'|'|"|"|…|–|—|\||#/g, ''));

				if (sentences.length === 0) {
					running.delete(sessionID);
					return;
				}

				try {
					const generateAudio = async (sentence: string): Promise<Uint8Array> => {
						const { stdout } = await $`echo ${sentence} | piper -m ${voice} --output-raw`.quiet();
						return stdout;
					};

					let nextAudio = generateAudio(sentences[0]);

					for (let i = 0; i < sentences.length; i++) {
						const sentence = sentences[i];
						const audio = await nextAudio;

						if (i + 1 < sentences.length) {
							nextAudio = generateAudio(sentences[i + 1]);
						}

						$`echo ${sentence} | aosd_cat --font="Sans Bold 60" --fore-color=white --back-color=black --position=7 --x-offset=0 --y-offset=-30 --fade-in=100 --fade-full=60000 --fade-out=3000`.quiet().nothrow().then();
						await $`ffplay -af atempo=1.25 -v error -nodisp -autoexit -f s16le -ar 24000 -i pipe:0 < ${audio}`.quiet();
						await $`killall aosd_cat`.catch(() => { });
					}
				} finally {
					running.delete(sessionID);
				}
			}
		},
	}
}
