import { CharStream, CommonTokenStream } from 'antlr4';
import LuaLexer from './grammar/LuaLexer.js';
import LuaParser, { Start_Context } from './grammar/LuaParser.js';
import { CodeGenerator } from './codeGenerator/generator.js';

// Need error handling and error reporting
function parseCode(code: string): Start_Context {
    const chars = new CharStream(code);
    const lexer = new LuaLexer(chars);
    const tokens = new CommonTokenStream(lexer);
    const parser = new LuaParser(tokens);

    return parser.start_();
}

function preprocessCode(code: string): string {
    const tree = parseCode(code);

    const gen = new CodeGenerator();
    const codePreprocessed = gen.convert(tree);

    return codePreprocessed;
}

export { preprocessCode }