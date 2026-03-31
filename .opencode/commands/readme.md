---
description: Generate a README.md by answering questions
agent: build
---

I want to create a README.md for my project. I'll provide a template name as the first argument. Available templates are in `.opencode/readme-templates/`:

- **minimal** - Just title, description, usage, license
- **npm** - For npm packages with install, usage, API sections
- **cli** - For command-line tools with quick start, examples
- **api** - For APIs with overview, architecture, endpoints

Use `$1` as the template name. If no template is specified, ask me which one I want.

Please ask me the following questions one by one and wait for my answers:

1. What is the name of the project?
2. Why is this project worth working on? (Explain the core reason - be specific)
3. What is the first step to get started?
4. What would the complete project look like when finished?
5. How many days will you work on this? (one day, two days, three days, four days, five days, one week, two weeks, etc.)
6. For each day, what needs to be done? (I'll provide details for each day)
7. When will the project be finished? (e.g., tomorrow, in 2 days, next week, etc.)
8. How do you feel right now?
9. What about the project - how do you feel about it?

IMPORTANT: If my answers are vague or lack detail, ask follow-up questions to get more specific information before generating the README.

After collecting all this information, create a well-formatted README.md in the current directory based on the chosen template. Fill in the template placeholders with my answers.

To review and improve the generated README, run: `/review`

Generate the file and show me the result.
