const { PutObjectCommand, DeleteObjectCommand } = require("@aws-sdk/client-s3");
const r2 = require("./r2");

const uploadToR2 = async (file, folder = "uploads") => {
  if (!file) return null;

  const key = `${folder}/${Date.now()}_${file.originalname}`;

  await r2.send(
    new PutObjectCommand({
      Bucket: process.env.R2_BUCKET,
      Key: key,
      Body: file.buffer,
      ContentType: file.mimetype,
    })
  );

  return `${process.env.R2_ENDPOINT}/${process.env.R2_BUCKET}/${key}`;
};

const deleteFromR2 = async (fileUrl) => {
  try {
    if (!fileUrl) return;

    const base = `${process.env.R2_ENDPOINT}/${process.env.R2_BUCKET}/`;
    if (!fileUrl.startsWith(base)) return;

    const key = fileUrl.replace(base, "");

    await r2.send(
      new DeleteObjectCommand({
        Bucket: process.env.R2_BUCKET,
        Key: key,
      })
    );
  } catch (err) {
    console.error("R2 delete error:", err.message);
  }
};

module.exports = { uploadToR2, deleteFromR2 };
