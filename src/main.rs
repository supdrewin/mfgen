use std::collections::BTreeMap;
use std::ffi::OsStr;
use std::fs;
use std::io::{self, Write as _};

use serde_json::Value;
use walkdir::WalkDir;

fn main() -> io::Result<()> {
    let mut patch = fs::OpenOptions::new().create(true).truncate(true).write(true).open("patch.js")?;
    let mut map = BTreeMap::new();

    writeln!(&mut patch, "// Generated from: https://github.com/supdrewin/mfgen")?;
    writeln!(&mut patch, "// Current version: v{}", env!("CARGO_PKG_VERSION"))?;
    writeln!(&mut patch, "var id = setInterval(() => {{")?;
    writeln!(&mut patch, "\tLAppModel.prototype._loadAssets = LAppModel.prototype.loadAssets;")?;
    writeln!(&mut patch, "\tLAppModel.prototype.loadAssets = function (dir, fileName) {{")?;
    writeln!(&mut patch, "\t\tthis._loadAssets(dir, fileName);")?;
    writeln!(&mut patch, "\t\tif (Live2DCubismCore.Model.prototype._update) {{")?;
    writeln!(&mut patch, "\t\t\tLive2DCubismCore.Model.prototype.update = Live2DCubismCore.Model.prototype._update;")?;
    writeln!(&mut patch, "\t\t}}")?;
    writeln!(&mut patch, "\t\tif (fileName == \"SH_JinYueShi.model3.json\") {{")?;
    writeln!(&mut patch, "\t\t\tLive2DCubismCore.Model.prototype._update ??= Live2DCubismCore.Model.prototype.update;")?;
    writeln!(&mut patch, "\t\t\tLive2DCubismCore.Model.prototype.update = function () {{")?;
    writeln!(&mut patch, "\t\t\t\tthis._update();")?;
    writeln!(&mut patch, "\t\t\t\tthis.drawables.opacities.forEach((_, i, opacities) => {{")?;
    writeln!(&mut patch, "\t\t\t\t\tif (this.drawables.parentPartIndices[i] < 0) opacities[i] = 0;")?;
    writeln!(&mut patch, "\t\t\t\t}});")?;
    writeln!(&mut patch, "\t\t\t}};")?;

    for entry in WalkDir::new("asset/image/live2d").into_iter().filter_map(Result::ok) {
        let path = entry.path();

        match path.file_name().map(OsStr::to_str).flatten() {
            Some(name) if name.ends_with(".model3.json") => {
                let mut _parts = vec![];

                let json = serde_json::from_str::<Value>(&fs::read_to_string(path)?)?;
                let path = path.parent().unwrap().join(json["FileReferences"]["DisplayInfo"].as_str().unwrap());

                let json = serde_json::from_str::<Value>(&fs::read_to_string(path)?)?;
                let parts = json["Parts"].as_array().unwrap();

                for (i, part) in parts.iter().enumerate() {
                    let name = part["Name"].as_str().unwrap();

                    if name == "效果组" || name.contains("雾") {
                        _parts.push(i);
                    }
                }

                if !_parts.is_empty() {
                    map.insert(name.to_string(), _parts);
                }
            }
            _ => (),
        }
    }

    map.insert("LH_MengYao.model3.json".to_string(), vec![0]);
    map.insert("ys_suxi.model3.json".to_string(), vec![3, 5]);

    map.remove("HSQ_MengYao.model3.json");

    for (name, parts) in map {
        writeln!(&mut patch, "\t\t}} else if (fileName == \"{name}\") {{")?;
        writeln!(&mut patch, "\t\t\tLAppModel.prototype._loadModel ??= LAppModel.prototype.loadModel;")?;
        writeln!(&mut patch, "\t\t\tLAppModel.prototype.loadModel = function (buffer, shouldCheckMocConsistency) {{")?;
        writeln!(&mut patch, "\t\t\t\tthis._loadModel(buffer, shouldCheckMocConsistency);")?;

        for i in parts {
            writeln!(&mut patch, "\t\t\t\tthis._model.setPartOpacityByIndex({i}, 0);")?;
        }

        writeln!(&mut patch, "\t\t\t\tLAppModel.prototype.loadModel = LAppModel.prototype._loadModel;")?;
        writeln!(&mut patch, "\t\t\t}};")?;
    }

    writeln!(&mut patch, "\t\t}}")?;
    writeln!(&mut patch, "\t}};")?;
    writeln!(&mut patch, "\tclearInterval(id);")?;
    writeln!(&mut patch, "}}, 1000);")?;

    Ok(())
}
