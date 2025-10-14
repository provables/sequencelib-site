import { exec } from "child_process";
import utils from "util";

const execute = utils.promisify(exec);
const result = JSON.parse((await execute("./src/components/_lean_info.py")).stdout);

export { result };