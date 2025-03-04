package com.anand.kmp.data

import kotlinx.serialization.Serializable
import kotlin.experimental.ExperimentalObjCName
import kotlin.native.ObjCName

@Serializable
@OptIn(ExperimentalObjCName::class)
@ObjCName("PostModel")
data class Post(
    val userId: Int,
    val id: Int,
    val title: String,
    val body: String
) 