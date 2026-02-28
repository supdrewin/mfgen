use std::collections::BTreeMap;
use std::ffi::OsStr;
use std::fs;
use std::io::{self, Write as _};

use serde_json::Value;
use walkdir::WalkDir;

fn main() -> io::Result<()> {
    let mut patch = fs::OpenOptions::new().create(true).truncate(true).write(true).open("patch.js")?;
    let mut map = BTreeMap::new();

    patch.write_fmt(format_args!("// Generated from: https://github.com/supdrewin/mfgen\n"))?;
    patch.write_fmt(format_args!("var id = setInterval(() => {{\n"))?;
    patch.write_fmt(format_args!("\tLAppModel.prototype._loadAssets = LAppModel.prototype.loadAssets;\n"))?;
    patch.write_fmt(format_args!("\tLAppModel.prototype.loadAssets = function (dir, fileName) {{\n"))?;
    patch.write_fmt(format_args!("\t\tthis._loadAssets(dir, fileName);\n"))?;
    patch.write_fmt(format_args!("\t\tif (fileName == \"SH_JinYueShi.model3.json\") {{\n"))?;
    patch.write_fmt(format_args!("\t\t\tLive2DCubismCore.Model.prototype._update ??= Live2DCubismCore.Model.prototype.update;\n"))?;
    patch.write_fmt(format_args!("\t\t\tLive2DCubismCore.Model.prototype.update = function () {{\n"))?;
    patch.write_fmt(format_args!("\t\t\t\tthis._update();\n"))?;
    patch.write_fmt(format_args!("\t\t\t\tthis.drawables.opacities.forEach((_, i, opacities) => {{\n"))?;
    patch.write_fmt(format_args!("\t\t\t\t\tif (this.drawables.parentPartIndices[i] < 0) opacities[i] = 0;\n"))?;
    patch.write_fmt(format_args!("\t\t\t\t}});\n"))?;
    patch.write_fmt(format_args!("\t\t\t}};\n"))?;

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

                map.insert(name.to_string(), _parts);
            }
            _ => (),
        }
    }

    map.insert("LH_MengYao.model3.json".to_string(), vec![0]);
    map.insert("ys_suxi.model3.json".to_string(), vec![3, 5]);

    map.remove("HSQ_MengYao.model3.json");

    for (name, mut parts) in map.into_iter().filter(|(_, parts)| !parts.is_empty()) {
        let i = parts.pop().unwrap();

        patch.write_fmt(format_args!("\t\t}} else if (fileName == \"{name}\") {{\n"))?;
        patch.write_fmt(format_args!("\t\t\tLive2DCubismCore.Model.prototype._update ??= Live2DCubismCore.Model.prototype.update;\n"))?;
        patch.write_fmt(format_args!("\t\t\tLive2DCubismCore.Model.prototype.update = function () {{\n"))?;
        patch.write_fmt(format_args!("\t\t\t\tthis._update();\n"))?;
        patch.write_fmt(format_args!("\t\t\t\tthis.drawables.opacities.forEach((_, i, opacities) => {{\n"))?;

        if parts.is_empty() {
            patch.write_fmt(format_args!("\t\t\t\t\tif (this.drawables.parentPartIndices[i] == {i}) opacities[i] = 0;\n"))?;
        } else {
            patch.write_fmt(format_args!("\t\t\t\t\tif (\n"))?;

            for i in parts {
                patch.write_fmt(format_args!("\t\t\t\t\t\tthis.drawables.parentPartIndices[i] == {i} ||\n"))?;
            }

            patch.write_fmt(format_args!("\t\t\t\t\t\tthis.drawables.parentPartIndices[i] == {i}\n"))?;
            patch.write_fmt(format_args!("\t\t\t\t\t) opacities[i] = 0;\n"))?;
        }

        patch.write_fmt(format_args!("\t\t\t\t}});\n"))?;
        patch.write_fmt(format_args!("\t\t\t}};\n"))?;
    }

    patch.write_fmt(format_args!("\t\t}} else if (Live2DCubismCore.Model.prototype._update) {{\n"))?;
    patch.write_fmt(format_args!("\t\t\tLive2DCubismCore.Model.prototype.update = Live2DCubismCore.Model.prototype._update;\n"))?;
    patch.write_fmt(format_args!("\t\t}}\n"))?;
    patch.write_fmt(format_args!("\t}};\n"))?;
    patch.write_fmt(format_args!("\tclearInterval(id);\n"))?;
    patch.write_fmt(format_args!("}}, 1000);\n"))?;

    Ok(())
}
