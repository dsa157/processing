const { exec } = require("child_process");

var cmd = "processing-java --sketch=/Users/dsa157/Documents/Processing/projects/CreateNFTs --output=/Users/dsa157/Documents/Processing/projects/out1 --force --run -Dmode=mint -Dnum=2 -DdataFile=cli-867-metadata.csv -DlogLevel=fine -Dhash=dsa157+gen.art";

exec(cmd, (error, stdout, stderr) => {
    if (error) {
        console.log(`error: ${error.message}`);
        return;
    }
    if (stderr) {
        console.log(`stderr: ${stderr}`);
        return;
    }
    console.log(`stdout: ${stdout}`);
});
