use std::ffi::OsStr;
use std::fs;
use std::fs::OpenOptions;
use std::io::Write;

use serde_json::Value;
use walkdir::WalkDir;

#[rustfmt::skip]
fn main() -> anyhow::Result<()> {
    let mut patch = OpenOptions::new()
        .create(true)
        .write(true)
        .open("patch.js")?;

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

    for entry in WalkDir::new("asset/image/live2d")
        .into_iter()
        .filter_map(Result::ok)
    {
        let path = entry.path();

        match path.file_name().map(OsStr::to_str).flatten().as_deref() {
            Some(name) if name.ends_with(".model3.json") => {
                let mut result: Vec<usize> = vec![];

                for (i, part) in serde_json::from_str::<Value>(
                    &fs::read_to_string(path.parent().unwrap().join(
                        serde_json::from_str::<Value>(&fs::read_to_string(path)?)?
                        ["FileReferences"]["DisplayInfo"].as_str().unwrap()))?
                )?["Parts"].as_array().unwrap().iter().enumerate() {
                    if part["Name"].as_str().unwrap().contains("雾") {
                        result.push(i);
                    }
                }

                if !result.is_empty() {
                    let i = result.pop().unwrap();

                    patch.write_fmt(format_args!("\t\t}} else if (fileName == \"{name}\") {{\n"))?;
                    patch.write_fmt(format_args!("\t\t\tLive2DCubismCore.Model.prototype._update ??= Live2DCubismCore.Model.prototype.update;\n"))?;
                    patch.write_fmt(format_args!("\t\t\tLive2DCubismCore.Model.prototype.update = function () {{\n"))?;
                    patch.write_fmt(format_args!("\t\t\t\tthis._update();\n"))?;
                    patch.write_fmt(format_args!("\t\t\t\tthis.drawables.opacities.forEach((_, i, opacities) => {{\n"))?;
                    patch.write_fmt(format_args!("\t\t\t\t\tif (\n"))?;

                    for i in result {
                        patch.write_fmt(format_args!(
                            "\t\t\t\t\t\tthis.drawables.parentPartIndices[i] == {i} ||\n"
                        ))?;
                    }

                    patch.write_fmt(format_args!("\t\t\t\t\t\tthis.drawables.parentPartIndices[i] == {i}\n"))?;
                    patch.write_fmt(format_args!("\t\t\t\t\t) opacities[i] = 0;\n"))?;
                    patch.write_fmt(format_args!("\t\t\t\t}});\n"))?;
                    patch.write_fmt(format_args!("\t\t\t}};\n"))?;
                }
            }
            _ => (),
        };
    }

    patch.write_fmt(format_args!("\t\t}} else if (Live2DCubismCore.Model.prototype._update) {{\n"))?;
    patch.write_fmt(format_args!("\t\t\tLive2DCubismCore.Model.prototype.update = Live2DCubismCore.Model.prototype._update;\n"))?;
    patch.write_fmt(format_args!("\t\t}}\n"))?;
    patch.write_fmt(format_args!("\t}};\n"))?;
    patch.write_fmt(format_args!("\tclearInterval(id);\n"))?;
    patch.write_fmt(format_args!("}}, 1000);\n"))?;

    Ok(())
}
