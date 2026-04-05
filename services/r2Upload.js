const { PutObjectCommand, DeleteObjectCommand } = require("@aws-sdk/client-s3");
const r2 = require("./r2");

const uploadToR2 = async (file, folder = "uploads") => {
  if (!file) return null;

  const key = `${folder}/${Date.now()}_${file.originalname}`;

  console.log("Uploading to R2...");
  console.log("Bucket:", process.env.R2_BUCKET_NAME);

  await r2.send(
    new PutObjectCommand({
      Bucket: process.env.R2_BUCKET_NAME, // ✅ FIXED
      Key: key,
      Body: file.buffer,
      ContentType: file.mimetype,
    })
  );

  return `https://pub-e399cf5ff7684c79b45518f9c1c09c37.r2.dev/${key}`;
};

const deleteFromR2 = async (fileUrl) => {
  try {
    if (!fileUrl) return;

    const base = `${process.env.R2_ENDPOINT}/${process.env.R2_BUCKET_NAME}/`;

    if (!fileUrl.startsWith(base)) return;

    const key = fileUrl.replace(base, "");

    await r2.send(
      new DeleteObjectCommand({
        Bucket: process.env.R2_BUCKET_NAME, // ✅ FIXED
        Key: key,
      })
    );
  } catch (err) {
    console.error("R2 delete error:", err.message);
  }
};

module.exports = { uploadToR2, deleteFromR2 };
