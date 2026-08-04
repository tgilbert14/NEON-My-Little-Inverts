import fs from "node:fs";

const files = ["ui.R", "www/app.js", "www/pincards.js"];
const expectedNames = [
  "countUp",
  "invSaveSite",
  "kickMaps",
  "loadDone",
  "smtLoadStart",
];
const registrationPatterns = [
  /\binvAddH\(\s*["']([^"']+)["']\s*,\s*function\s*\(([^)]*)\)/g,
  /\bShiny\.addCustomMessageHandler\(\s*["']([^"']+)["']\s*,\s*function\s*\(([^)]*)\)/g,
];
const literalRegistrationPattern =
  /\b(?:invAddH|Shiny\.addCustomMessageHandler)\(\s*["'][^"']+["']/g;

const handlers = [];
let literalRegistrations = 0;

for (const file of files) {
  const source = fs.readFileSync(file, "utf8");
  literalRegistrations += [...source.matchAll(literalRegistrationPattern)].length;

  for (const pattern of registrationPatterns) {
    for (const match of source.matchAll(pattern)) {
      handlers.push({ file, name: match[1], paramsText: match[2] });
    }
  }
}

if (handlers.length !== literalRegistrations) {
  throw new Error(
    `found ${literalRegistrations} literal handler registrations but parsed ${handlers.length}; ` +
      "register handlers with function (payload) so the contract can inspect them",
  );
}

const invalid = handlers.filter(({ paramsText }) => {
  const params = paramsText
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean);
  return params.length !== 1 || !/^[A-Za-z_$][\w$]*$/.test(params[0]);
});

if (invalid.length) {
  throw new Error(
    "Shiny custom message handlers must accept exactly one payload argument:\n" +
      invalid
        .map(({ file, name, paramsText }) => `${file}: ${name}(${paramsText})`)
        .join("\n"),
  );
}

const actualNames = handlers.map(({ name }) => name).sort();
const duplicateNames = actualNames.filter(
  (name, index) => index > 0 && name === actualNames[index - 1],
);

if (duplicateNames.length) {
  throw new Error(`duplicate Shiny custom message handlers: ${[...new Set(duplicateNames)].join(", ")}`);
}

if (JSON.stringify(actualNames) !== JSON.stringify(expectedNames)) {
  throw new Error(
    `expected handlers [${expectedNames.join(", ")}], found [${actualNames.join(", ")}]`,
  );
}

console.log(
  `OK: ${handlers.length} Shiny custom message handlers accept exactly one payload argument.`,
);
